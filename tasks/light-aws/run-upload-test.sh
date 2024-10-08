#!/usr/bin/env bash

set -e

source bosh-cpi-src/ci/utils.sh
source director-state/director.env

pushd stemcell
  time bosh -n upload-stemcell *.tgz
popd

