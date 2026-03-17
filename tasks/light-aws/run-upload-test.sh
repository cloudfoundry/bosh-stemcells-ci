#!/usr/bin/env bash

set -e

REPO_ROOT="$( cd "$( dirname "${BASH_SOURCE[0]}" )/../.." && pwd )"
REPO_PARENT="$( cd "${REPO_ROOT}/.." && pwd )"

source "${REPO_PARENT}/director-state/director.env"

pushd "${REPO_PARENT}/stemcell"
  time bosh -n upload-stemcell *.tgz
popd

