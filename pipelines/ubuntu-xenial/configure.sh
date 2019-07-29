#!/usr/bin/env bash

set -euo pipefail

until lpass status;do
  LPASS_DISABLE_PINENTRY=1 lpass ls a
done

until fly -t production status;do
  fly -t production login
done

dir=$(dirname $0)

interpolated=$(mktemp)

bosh interpolate \
  -o <( bosh int -v group=master -v branch=master -v initial_version=0.0.0  -v bump_version=major -v bosh_agent_version='"*"' "$dir/pipeline-base-ops.yml" ) \
  -o "$dir/pipeline-master-ops.yml" \
  "${dir}/pipeline-base.yml" > "${interpolated}"

while read -r xenial_line bosh_agent_version; do
  bosh interpolate \
    -o <(bosh int -v group="${xenial_line}.x"  -v branch="ubuntu-xenial/${xenial_line}.x"  -v initial_version="${xenial_line}.0.0" -v bump_version=minor -v bosh_agent_version="${bosh_agent_version}.*" "$dir/pipeline-base-ops.yml") \
    -o <(bosh int -v group="${xenial_line}.x"  -v branch="ubuntu-xenial/${xenial_line}.x"  -v initial_version="${xenial_line}.0.0" -v bump_version=minor "$dir/pipeline-branch-ops.yml") \
    "$interpolated" > "${interpolated}.next"

  mv "${interpolated}.next" "$interpolated"
done < "${dir}/stemcell-lines.txt"

bosh interpolate \
  -o "${dir}/../../ops-files/97.x-delete-alicloud-build-ops.yml" \
  "$interpolated" > "${interpolated}.next"
mv "${interpolated}.next" "$interpolated"

fly -t production set-pipeline \
  -p "bosh:stemcells:ubuntu-xenial" \
  -l <(lpass show --notes "concourse:production pipeline:os-images" ) \
  -l <(lpass show --notes "concourse:production pipeline:bosh:stemcells" ) \
  -l <(lpass show --notes "bats-concourse-pool:vsphere secrets" ) \
  -l <(lpass show --notes "stemcell-reminder-bot") \
  -c "$interpolated"
