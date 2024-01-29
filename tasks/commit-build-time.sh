#!/usr/bin/env bash

set -euo pipefail

build_time="$(cat ./build-time/timestamp)"
formatted_build_time="$(date --date "${build_time%.*}" +%Y%m%dT%H%M%SZ)"

pushd bosh-linux-stemcell-builder
  echo "${formatted_build_time}" > build_time.txt
  git add -A
  git config --global user.email "ci@localhost"
  git config --global user.name "CI Bot"
  git commit -m "Commit Build Time"
popd
