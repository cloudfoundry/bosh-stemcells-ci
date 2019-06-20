#!/bin/bash

set -euo pipefail

usn_json="${PWD}/usn-source/usn.json"

commit_body=$(cat <<EOF
url: $(jq -r .url "${usn_json}")
priorities: $(jq -r '.priorities | join(",")' "${usn_json}")
description: $(jq -r .description "${usn_json}")
cves:
  $(jq -r '.cves[] | "* \(.)"' "${usn_json}")
EOF
)

pushd bosh-linux-stemcell-builder
  git add -A
  git config --global user.email "ci@localhost"
  git config --global user.name "CI Bot"
  git commit --allow-empty -m "$(jq -r .title "${usn_json}")" -m "${commit_body}"
popd
