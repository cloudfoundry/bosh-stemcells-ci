#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$( cd "$( dirname "${0}" )" && pwd )"

source "${SCRIPT_DIR}/usn-processing/usn-shared-functions.sh"

process_usns "usn-log-in/usn-log.json"


if [ "$ALL_PACKAGE_VERSIONS_AVAILABLE" != true ]
then
  echo "Not all vulnerable packages have available fixes yet, deferring stemcell build."
  exit 1
else
  exit 0
fi
