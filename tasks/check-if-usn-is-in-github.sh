#!/usr/bin/env bash

set -euo pipefail
usn_json="${PWD}/usn/usn.json"

# add the new usn to the list of unfound usns
touch joined-usns
cp unfound-usns/usns.json joined-usns
cat "${usn_json}" >> joined-usns

# turn the unfound usns into an array
mapfile -t UNFOUND_USNS < joined-usns

# check if each of the unfound usns is in github
touch found-usns/usns.json
touch updated-unfound-usns/usns.json
for usn in "${UNFOUND_USNS[@]}"; do
    id=$(echo $usn | jq -r '.url' | cut -d '/' -f6 | cut -d '-' -f2,3)
    echo "checking for USN-${id} in github..."

    if [[ -f "usn-gh-json/usn/${id}.json" ]]; then
        echo "found ${id}.json "
        echo $usn >> found-usns/usns.json
    else
        echo "${id}.json not found"
        echo $usn >> updated-unfound-usns/usns.json
    fi
done