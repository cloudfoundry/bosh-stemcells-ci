#!/usr/bin/env bash

set -e

echo "Running unit tests"

pushd builder-src/src/light-stemcell-builder > /dev/null
  ginkgo -p -r -skipPackage "driver,integration"
  ginkgo -p -r driverset # driverset is skipped by previous command
popd
