#!/usr/bin/env bash

set -e

FLY="${FLY_CLI:-fly}"

until lpass status;do
  LPASS_DISABLE_PINENTRY=1 lpass ls a
  sleep 1
done

until "$FLY" -t "${CONCOURSE_TARGET:-bosh-ecosystem}" status;do
  "$FLY" -t "${CONCOURSE_TARGET:-bosh-ecosystem}" login
  sleep 1
done

pipeline_config=$(mktemp)
ytt -f "$(dirname $0)" > $pipeline_config
# ytt -f "$(dirname $0)"

"$FLY" -t "${CONCOURSE_TARGET:-bosh-ecosystem}" set-pipeline \
  -p "stemcells-ubuntu-xenial" \
  -l <(lpass show --notes "stemcell-reminder-bot") \
  -l <(lpass show --notes "concourse:production pipeline:bosh:stemcells lts") \
  -c "$pipeline_config"

