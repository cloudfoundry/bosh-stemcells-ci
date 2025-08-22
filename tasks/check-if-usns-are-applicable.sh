#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$( cd "$( dirname "${0}" )" && pwd )"

source "${SCRIPT_DIR}/usn-processing/usn-shared-functions.sh"

packages_included_in_stemcell=false
mapfile -t FOUND_USNS < usns/usns.json
for usn in "${FOUND_USNS[@]}"; do
  id=$(echo $usn | jq -r '.url' | cut -d '/' -f6 | cut -d '-' -f2,3)

  usn_json="${PWD}/usn.json"
  echo $usn > $usn_json
  process_usns "${usn_json}" "usn-gh-json/usn"


  if [ "$PACKAGE_INCLUDED_IN_STEMCELL" == true ]
  then
    jq -s --slurpfile new_usn ${usn_json} '. + $new_usn | unique_by(.url) | .[]' >> updated-usn-log/usn-log.json < usn-log/usn-log.json
    packages_included_in_stemcell=true
  else
    echo "Packages for USN-${id} are not included in stemcell"
  fi

  PACKAGE_INCLUDED_IN_STEMCELL=false
done

if $packages_included_in_stemcell; then
  echo "true" > updated-usn-log/success
  exit 0
else
  echo "true" > updated-usn-log/success
  exit 1
fi
