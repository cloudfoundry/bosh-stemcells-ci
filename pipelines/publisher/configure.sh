#!/usr/bin/env bash

set -e

FLY="${FLY_CLI:-fly}"

until lpass status;do
  LPASS_DISABLE_PINENTRY=1 lpass ls a
  sleep 1
done

until "$FLY" -t "${CONCOURSE_TARGET:-main}" status;do
  "$FLY" -t "${CONCOURSE_TARGET:-main}" login
  sleep 1
done

pipeline_config=$(mktemp)
ytt -f "$(dirname $0)" > $pipeline_config

"$FLY" -t "${CONCOURSE_TARGET:-main}" set-pipeline \
  -p stemcells:publisher \
  -c $pipeline_config \
bosh int /tmp/used_variables.txt \
-l <(lpass show --notes "bionic_oss_stemcell_publisher.yml")
