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
ytt --dangerous-allow-all-symlink-destinations \
    -f "$(dirname $0)" > $pipeline_config

name="$( basename $( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd ))"
"$FLY" -t "${CONCOURSE_TARGET:-main}" set-pipeline \
  -p "bosh:stemcells:${name}" \
  -l <(lpass show --notes "concourse:production pipeline:os-images" ) \
  -l <(lpass show --notes "concourse:production pipeline:bosh:stemcells" ) \
  -l <(lpass show --notes "bosh-agent concourse secrets" ) \
  -l <(lpass show --notes "bats-concourse-pool:vsphere secrets" ) \
  -l <(lpass show --notes "bats-concourse-pool:vsphere nimbus secrets" ) \
  -l <(lpass show --notes "bosh:docker-images concourse secrets" ) \
  -l <(lpass show --notes "stemcell-reminder-bot") \
  -c "$pipeline_config"
