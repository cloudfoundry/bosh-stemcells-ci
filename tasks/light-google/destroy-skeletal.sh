#!/usr/bin/env bash
set -eu -o pipefail

REPO_ROOT="$( cd "$( dirname "${BASH_SOURCE[0]}" )/../.." && pwd )"
REPO_PARENT="$( cd "${REPO_ROOT}/.." && pwd )"

pushd "${REPO_PARENT}/deployment-state" > /dev/null
  echo "Destroying skeletal instance..."

  set +e
  bosh -n delete-env ./skeletal-deployment.yml
  exit_code=$?
  set -e

  if [ "${exit_code}" == "0" ]; then
    echo "Successfully destroyed!"
  else
    echo "Failed to destroy deployment, continuing..."
  fi

popd > /dev/null
