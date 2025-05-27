import json
import yaml
import argparse
from pathlib import Path

# This script checks locale files in frontendPath and backendPath
# for uses of "post" instead of "toot" and prints found results

parser = argparse.ArgumentParser()
parser.add_argument('-p', '--project', type=Path, help='Path to Mastodon source dir to check', default='.')
parser.add_argument('-i', '--ignored-keys', nargs='*', help='Locale keys to ignore', default=['dmca_address'])

args = parser.parse_args()
projectPath = args.project
ignoredKeys = args.ignored_keys

frontendPaths = ['app/javascript/mastodon/locales', 'app/javascript/flavours/glitch/locales', 'app/javascript/flavours/polyam/locales']
backendPaths = ['config/locales', 'config/locales-glitch', 'config/locales-polyam']

def get_key_value(d):
  for key, value in d.items():
    if isinstance(value, dict):
      yield from get_key_value(value)
    else:
      yield key, value

def check_files(paths):
  files = []
  for localePath in paths:
    files.extend([f for f in Path(projectPath, localePath).glob('*en*.[json yml]*') if f.is_file()])
  
  for localeFile in files:
    with open(localeFile) as reading:
      fileType = localeFile.suffix

      match fileType:
        case '.json':
          data = json.loads(reading.read()).items()
        case '.yml':
          data = get_key_value(yaml.safe_load(reading))
        case _:
          print(f'{localeFile.relative_to(projectPath)} has unsupported suffix: {fileType}')
          exit(2)
      
      for key, localeString in data:
        if localeString is not None and 'post'.casefold() in localeString.casefold() and key not in ignoredKeys:
          print(f'{localeFile.relative_to(projectPath)}: {key} contains "post" instead of "toot"')

check_files(frontendPaths + backendPaths)
