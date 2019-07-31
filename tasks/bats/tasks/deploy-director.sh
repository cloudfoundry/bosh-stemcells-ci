#!/usr/bin/env bash

source /etc/profile.d/chruby.sh
chruby ruby

set -ex

: ${BAT_INFRASTRUCTURE:?}

export BUILD_DIR=$PWD

vars_file=$(mktemp)
$BUILD_DIR/bosh-stemcells-ci/tasks/bats/iaas/$BAT_INFRASTRUCTURE/director-vars > $vars_file

mv bosh-cli/bosh-cli-* /usr/local/bin/bosh-cli
chmod +x /usr/local/bin/bosh-cli

mkdir -p director-state
cd director-state

bosh-cli interpolate $BUILD_DIR/bosh-deployment/bosh.yml \
  -o $BUILD_DIR/bosh-deployment/$BAT_INFRASTRUCTURE/cpi.yml \
  -o $BUILD_DIR/bosh-deployment/$BAT_INFRASTRUCTURE/resource-pool.yml \
  -o $BUILD_DIR/bosh-deployment/misc/powerdns.yml \
  -o $BUILD_DIR/bosh-deployment/jumpbox-user.yml \
  -o $BUILD_DIR/bosh-stemcells-ci/tasks/bats/ops/remove-health-monitor.yml \
  -v dns_recursor_ip=8.8.8.8 \
  -v director_name=bats-director \
  --vars-file "${vars_file}" \
  > director.yml

bosh-cli create-env \
  --state director-state.json \
  --vars-store director-creds.yml \
  director.yml
