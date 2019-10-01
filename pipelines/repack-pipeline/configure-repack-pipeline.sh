#!/usr/bin/env bash

set -euo pipefail

until lpass status;do
  LPASS_DISABLE_PINENTRY=1 lpass ls a
done

until fly -t production status;do
  fly -t production login
done

fly -t production set-pipeline \
  -p "test:repack-pipeline" \
  -l <(lpass show --notes "concourse:production pipeline:os-images" ) \
  -l <(lpass show --notes "concourse:production pipeline:bosh:stemcells" ) \
  -l <(lpass show --notes "bats-concourse-pool:vsphere secrets" ) \
  -l <(lpass show --notes "stemcell-reminder-bot") \
  -c repack-pipeline.yml
