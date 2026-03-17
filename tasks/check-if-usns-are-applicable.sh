#!/usr/bin/env bash
set -eu -o pipefail

REPO_ROOT="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )"
REPO_PARENT="$( cd "${REPO_ROOT}/.." && pwd )"

source "${REPO_ROOT}/tasks/usn-processing/usn-shared-functions.sh"

packages_included_in_stemcell=false
mapfile -t FOUND_USNS < "${REPO_PARENT}/usns/usns.json"
for usn in "${FOUND_USNS[@]}"; do
  id=$(echo $usn | jq -r '.url' | cut -d '/' -f6 | cut -d '-' -f2,3)

  usn_json="${REPO_PARENT}/usn.json"
  echo $usn > $usn_json
  process_usns "${usn_json}" "${REPO_PARENT}/usn-gh-json/usn"


  if [ "$PACKAGE_INCLUDED_IN_STEMCELL" == true ]
  then
    jq -s --slurpfile new_usn ${usn_json} '. + $new_usn | unique_by(.url) | .[]' \
      >> "${REPO_PARENT}/updated-usn-log/usn-log.json" < "${REPO_PARENT}/usn-log/usn-log.json"
    packages_included_in_stemcell=true
  else
    echo "Packages for USN-${id} are not included in stemcell"
  fi

  PACKAGE_INCLUDED_IN_STEMCELL=false
done

if $packages_included_in_stemcell; then
  echo "true" > "${REPO_PARENT}/updated-usn-log/success"
  exit 0
else
  echo "true" > "${REPO_PARENT}/updated-usn-log/success"
  exit 1
fi
