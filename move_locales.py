"""Manage locale files.

Primary usage is to extract deleted upstream strings.
"""

import json
import argparse
from pathlib import Path

parser = argparse.ArgumentParser()
parser.add_argument("-i", "--in", type=Path, help="Path to locales to extract", dest="input")
parser.add_argument("-o", "--out", type=Path, help="Path to new locales", dest="output")
parser.add_argument(
    "-c",
    "--copy",
    action=argparse.BooleanOptionalAction,
    help="Do not delete from input",
    dest="copy",
)

args = parser.parse_args()
outputPath = args.output
inputPath = args.input
copy = args.copy

file = Path(outputPath, "en.json")
data = {}

# Read and load en.json from output dir; used as baseline
if file.is_file():
    with open(file) as reading:
        data = json.loads(reading.read())

if not data:
    print("Couldn't load strings from en.json")
    exit(2)

# Read files from input dir
for child in Path(inputPath).glob("*.json"):
    if child.is_file():
        with open(child) as localeFile:
            lines = json.loads(localeFile.read())
            # Strings present in old locales, which belong to new locales.
            # Will be removed from old locales
            to_delete = []

            for attribute, value in lines.items():
                newFile = Path(outputPath, child.name)
                newData = data.copy()

                if newFile.is_file():
                    with open(newFile) as newLocaleFile:
                        # Keep locales in newLocalFile
                        currentData = json.loads(newLocaleFile.read())
                        newData = newData | currentData

                if attribute in data:
                    newData[attribute] = value
                    to_delete.append(attribute)

                with open(newFile, "w") as newLocaleFile:
                    newLocaleFile.write(
                        json.dumps(newData, sort_keys=True, indent=2, ensure_ascii=False) + "\n"
                    )

        if not copy:
            # Open file again in write mode and delete strings present in en.json
            with open(child, "w") as localeFile:
                for attr in to_delete:
                    del lines[attr]

                localeFile.write(
                    json.dumps(lines, sort_keys=True, indent=2, ensure_ascii=False) + "\n"
                )
