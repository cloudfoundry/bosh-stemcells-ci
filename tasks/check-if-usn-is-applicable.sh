#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$( cd "$( dirname "${0}" )" && pwd )"

source "${SCRIPT_DIR}/usn-processing/usn-shared-functions.sh"
usn_json="${PWD}/usn/usn.json"
process_usns "${usn_json}"


if [ "$PACKAGE_INCLUDED_IN_STEMCELL" == true ]
then
  cp usn-log/usn-log.json existing-usn-log.json
  jq -s --slurpfile new_usn ${usn_json} '. + $new_usn | unique_by(.url) | .[]' > usn-log/usn-log.json < existing-usn-log.json
  echo "true" > usn-log/success
  exit 0
else
  echo "true" > usn-log/success
  echo "Packages for USN are not included in stemcell"
  exit 1
fi
