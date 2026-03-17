#!/usr/bin/env bash
set -eu -o pipefail

REPO_ROOT="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )"
REPO_PARENT="$( cd "${REPO_ROOT}/.." && pwd )"

build_time="$(cat "${REPO_PARENT}/build-time/timestamp")"
formatted_build_time="$(date --date "${build_time%.*}" +%Y%m%dT%H%M%SZ)"

pushd "${REPO_PARENT}/bosh-linux-stemcell-builder"
  echo "${formatted_build_time}" > build_time.txt
  git add -A
  git config --global user.email "ci@localhost"
  git config --global user.name "CI Bot"
  git commit -m "Commit Build Time"
popd
