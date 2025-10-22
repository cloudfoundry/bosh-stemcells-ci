#!/usr/bin/env bash
set -euo pipefail

cat << EOF > docker-build-args/docker-build-args.json
{
  "SYFT_VERSION": "$(cat syft-github-release/tag)",
}
EOF

cat docker-build-args/docker-build-args.json
