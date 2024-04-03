#!/usr/bin/env bash

set -e

FLY="${FLY_CLI:-fly}"

until "$FLY" -t "${CONCOURSE_TARGET:-bosh-fips}" status;do
  "$FLY" -t "${CONCOURSE_TARGET:-bosh-fips}" login
  sleep 1
done

pipeline_config=$(mktemp)
ytt --dangerous-allow-all-symlink-destinations \
    -f "$(dirname $0)" > $pipeline_config

name="$( basename $( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd ))"
"$FLY" -t "${CONCOURSE_TARGET:-bosh-fips}" set-pipeline \
  --team=stemcell \
  -p "stemcells-${name}" \
  -c "$pipeline_config"
