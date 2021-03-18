#!/usr/bin/env bash

set -euo pipefail

stemcell_line=$(echo $BRANCH | cut -f 1 -d "/")
stemcell_series_with_x=$(echo $BRANCH | cut -f 2 -d "/")
stemcell_series=$(echo $BRANCH | cut -f 2 -d "/" | cut -f 1 -d ".")
s3_trigger_file="s3://${BUCKET}/${stemcell_series_with_x}/stemcell-trigger"

now=$(date +%s)
three_weeks=1814400
let three_weeks_ago=now-${three_weeks}
echo "Three Weeks Ago: ${three_weeks_ago}"

pushd "stemcells-index/published/${stemcell_line}" > /dev/null
  latest_version=$(ls | sort --version-sort | grep "^${stemcell_series}" | tail -1)
  echo "Latest Cut Stemcell: ${latest_version}"
  latest_commit_date=$(git log --pretty="format:%ct" "${latest_version}" | head -n 1)
  echo "Latest Cut Stemcell Time: ${latest_commit_date}"
popd > /dev/null

trigger_file_modified_time=$(aws s3 ls ${s3_trigger_file} | cut -f 1,2 -d " ")
trigger_file_modified_epoch_time=$(date --date="${trigger_file_modified_time}" "+%s")
echo "Trigger File Modified Time: ${trigger_file_modified_epoch_time}"

if [ ( ${latest_commit_date} -lt ${three_weeks_ago} ) -a ( ${trigger_file_modified_epoch_time} -lt ${three_weeks_ago} ) ]
then
  echo "Periodic bump ($(date "+%b %e, %Y"))" > stemcell-trigger
  aws s3 cp ./stemcell-trigger ${s3_trigger_file}

  bosh-stemcells-ci/tasks/create-story.sh
fi
