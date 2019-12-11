#!/usr/bin/env bash

set -euo pipefail

until lpass status;do
  LPASS_DISABLE_PINENTRY=1 lpass ls a
done

until fly -t production status;do
  fly -t production login
done

dir=$(dirname $0)

fly -t production set-pipeline \
  -p "bosh:stemcells:centos-7" \
  -c <(
    bosh interpolate \
      -o <( bosh int -v group=3763.x -v branch=centos-7/3763.x -v initial_version="3763.0.0" -v bump_version=minor "$dir/3763.x/centos-7/pipeline-base-ops.yml" ) \
      -o <( bosh int -v group=3763.x -v branch=centos-7/3763.x -v initial_version="3763.0.0" -v bump_version=minor "$dir/3763.x/centos-7/pipeline-branch-ops.yml" ) \
      "$dir/pipeline-base.yml"
  ) \
  -l <( lpass show --notes "concourse:production pipeline:os-images" ) \
  -l <( lpass show --notes "concourse:production pipeline:bosh:stemcells" ) \
  -l <( lpass show --notes "bats-concourse-pool:vsphere secrets" ) \
  -l <(lpass show --notes "stemcell-reminder-bot")
