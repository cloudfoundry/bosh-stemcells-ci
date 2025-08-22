#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$( cd "$( dirname "${0}" )" && pwd )"

source "${SCRIPT_DIR}/usn-processing/usn-shared-functions.sh"
usn_json="${PWD}/usn/usn.json"
process_usns "${usn_json}" "usn-gh-json/usn"


if [ "$PACKAGE_INCLUDED_IN_STEMCELL" == true ]
then
  jq -s --slurpfile new_usn ${usn_json} '. + $new_usn | unique_by(.url) | .[]' > updated-usn-log/usn-log.json < usn-log/usn-log.json
  echo "true" > updated-usn-log/success
  exit 0
else
  echo "true" > updated-usn-log/success
  echo "Packages for USN are not included in stemcell"
  exit 1
fi
