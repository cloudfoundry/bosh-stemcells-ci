#!/usr/bin/env bash

set -e

FLY="${FLY_CLI:-fly}"

until "$FLY" -t "${CONCOURSE_TARGET:-bosh-ecosystem}" status;do
  "$FLY" -t "${CONCOURSE_TARGET:-bosh-ecosystem}" login
  sleep 1
done

pipeline_config=$(mktemp)
ytt -f "$(dirname $0)" > $pipeline_config
# ytt -f "$(dirname $0)"

"$FLY" -t "${CONCOURSE_TARGET:-bosh-ecosystem}" set-pipeline \
  -p "stemcells-ubuntu-xenial" \
  -v story_creator_tracker_project_id=2484143 \
  -v story_creator_private_tracker_project_id=2484143 \
  -c "$pipeline_config"

