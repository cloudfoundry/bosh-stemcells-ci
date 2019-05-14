#!/usr/bin/env bash

set -euo pipefail

dir="$(dirname "$0")"

fly -t production set-pipeline \
  -p "bosh:stemcells:ubuntu-bionic" \
  -c "$dir/pipeline.yml" \
  -l <( lpass show --notes "concourse:production pipeline:os-images" ) \
  -l <( lpass show --notes "concourse:production pipeline:bosh:stemcells" ) \
  -l <( lpass show --notes "bats-concourse-pool:vsphere secrets" ) \
  -l <(lpass show --notes "stemcell-reminder-bot")
