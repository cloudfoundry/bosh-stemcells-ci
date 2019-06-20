#!/usr/bin/env bash

set -euo pipefail

dir=$(dirname $0)

fly -t production set-pipeline \
  -p "bosh:stemcells:ubuntu-xenial" \
  -c <(
    bosh interpolate \
      -o <( bosh int -v group=master -v branch=master -v initial_version=0.0.0  -v bump_version=major -v bosh_agent_version='"*"' "$dir/pipeline-base-ops.yml" ) \
      -o <( bosh int "$dir/master/ubuntu-xenial/pipeline-master-ops.yml" ) \
      -o <( bosh int -v group=97.x -v branch=ubuntu-xenial/97.x -v initial_version=97.0.0 -v bump_version=minor "$dir/97.x/ubuntu-xenial/pipeline-base-ops.yml" ) \
      -o <( bosh int -v group=97.x -v branch=ubuntu-xenial/97.x -v initial_version=97.0.0 -v bump_version=minor "$dir/pipeline-branch-ops.yml" ) \
      -o <( bosh int -v group=170.x -v branch=ubuntu-xenial/170.x -v initial_version=170.0.0 -v bump_version=minor "$dir/170.x/ubuntu-xenial/pipeline-base-ops.yml" ) \
      -o <( bosh int -v group=170.x -v branch=ubuntu-xenial/170.x -v initial_version=170.0.0 -v bump_version=minor "$dir/pipeline-branch-ops.yml" ) \
      -o <( bosh int -v group=250.x -v branch=ubuntu-xenial/250.x -v initial_version=250.0.0 -v bump_version=minor -v bosh_agent_version='"2.193.*"' "$dir/pipeline-base-ops.yml" ) \
      -o <( bosh int -v group=250.x -v branch=ubuntu-xenial/250.x -v initial_version=250.0.0 -v bump_version=minor "$dir/pipeline-branch-ops.yml" ) \
      -o <( bosh int -v group=315.x -v branch=ubuntu-xenial/315.x -v initial_version=315.0.0 -v bump_version=minor -v bosh_agent_version='"2.215.*"' "$dir/pipeline-base-ops.yml" ) \
      -o <( bosh int -v group=315.x -v branch=ubuntu-xenial/315.x -v initial_version=315.0.0 -v bump_version=minor "$dir/pipeline-branch-ops.yml" ) \
      "$dir/master/ubuntu-xenial/pipeline-base.yml"
  ) \
  -l <( lpass show --notes "concourse:production pipeline:os-images" ) \
  -l <( lpass show --notes "concourse:production pipeline:bosh:stemcells" ) \
  -l <( lpass show --notes "bats-concourse-pool:vsphere secrets" ) \
  -l <(lpass show --notes "stemcell-reminder-bot")
