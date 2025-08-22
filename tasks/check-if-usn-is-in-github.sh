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
missing_usn=false
for usn in "${UNFOUND_USNS[@]}"; do
    id=$(echo $usn | jq -r '.url' | cut -d '/' -f6 | cut -d '-' -f2,3)
    echo "checking for USN-${id} in github..."

    if [[ -f "usn-gh-json/usn/${id}.json" ]]; then
        echo "found ${id}.json "
        echo $usn >> found-usns/usns.json
    else
        echo "${id}.json not found"
        echo $usn >> updated-unfound-usns/usns.json
        missing_usn=true
    fi
done

if $missing_usn; then
  echo "some USNs do not exist in github yet"
  echo "true" > found-usns/success
  exit 1
else
  echo "all USNs exist in github"
  echo "true" > found-usns/success
  exit 0
fi
