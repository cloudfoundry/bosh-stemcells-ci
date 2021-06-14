#!/usr/bin/env bash

set -e

FLY="${FLY_CLI:-fly}"

until "$FLY" -t "${CONCOURSE_TARGET:-bosh}" status;do
  "$FLY" -t "${CONCOURSE_TARGET:-bosh}" login
  sleep 1
done

pipeline_config=$(mktemp)
ytt -f "$(dirname $0)" > $pipeline_config

"$FLY" -t "${CONCOURSE_TARGET:-bosh}" set-pipeline \
  -p stemcells-publisher \
  -c $pipeline_config
