#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )"
REPO_PARENT="$( cd "${REPO_ROOT}/.." && pwd )"

cat << EOF > "${REPO_PARENT}/docker-build-args/docker-build-args.json"
{
  "SYFT_VERSION": "$(cat "${REPO_PARENT}/syft-github-release/tag")",
  "placeholder": "without trailing comma"
}
EOF

cat "${REPO_PARENT}/docker-build-args/docker-build-args.json"
