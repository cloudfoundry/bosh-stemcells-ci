#!/usr/bin/env bash
set -euo pipefail

echo "Running unit tests"

pushd builder-src > /dev/null
  go run github.com/onsi/ginkgo/v2/ginkgo -p -r --skip-package "driver,integration"
  go run github.com/onsi/ginkgo/v2/ginkgo -p -r driverset # driverset is skipped by previous command
popd
