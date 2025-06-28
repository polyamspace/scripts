"""Parses hellpot log files and prints top trash-eaters."""

import argparse
import json
import operator
from pathlib import Path

parser = argparse.ArgumentParser()
parser.add_argument(
    "-p", "--path", type=Path, default=".", help="specify path to hellpot logs (default: CWD)"
)
parser.add_argument(
    "-t", "--top", type=int, default=10, help="show top x results (default: %(default)s)"
)
parser.add_argument(
    "-e", "--exclude", type=str, default=[], help="list of IPs to exclude", nargs="+"
)
# TODO: Add arguments to get top results since a given date (maybe just since x days) and
# option to deduplicate results by IP

args = parser.parse_args()
path = args.path
top = args.top
excluded_ips = args.exclude

file_count = 0
full_data = []

for child in Path(path).glob("*.log"):
    if child.is_file():
        file_count += 1
        with open(child) as file:
            lines = file.readlines()
            for line in lines:
                data = json.loads(line)
                if data["message"] == "FINISH" and data["REMOTE_ADDR"] not in excluded_ips:
                    full_data.append(data)

full_data.sort(key=operator.itemgetter("BYTES"), reverse=True)

for data in full_data[:top]:
    data_bytes = round(int(data["BYTES"]) / (1000 * 1000 * 1000), 2)
    print(f"{data['REMOTE_ADDR']} {data['USERAGENT']} {data_bytes}GB {data['time']} {data['URL']}")

# print(f'Found {file_count} files!')
