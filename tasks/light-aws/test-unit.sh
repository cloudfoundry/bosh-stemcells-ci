#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$( cd "$( dirname "${BASH_SOURCE[0]}" )/../.." && pwd )"
REPO_PARENT="$( cd "${REPO_ROOT}/.." && pwd )"

echo "Running unit tests"

pushd "${REPO_PARENT}/builder-src" > /dev/null
  go run github.com/onsi/ginkgo/v2/ginkgo -p -r --skip-package "driver,integration"
  go run github.com/onsi/ginkgo/v2/ginkgo -p -r driverset # driverset is skipped by previous command
popd
