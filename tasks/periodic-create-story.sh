#!/usr/bin/env bash

set -eu

stemcell_line=$(echo $BRANCH | cut -f 1 -d "/")
stemcell_series_with_x=$(echo $BRANCH | cut -f 2 -d "/")
stemcell_series=$(echo $BRANCH | cut -f 2 -d "/" | cut -f 1 -d ".")

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

stories_count=$(curl --silent -X GET "https://www.pivotaltracker.com/services/v5/projects/$PROJECT_ID/stories?filter=created_since:$(date --date='3 weeks ago' '+%m/%d/%Y')%20name:stemcell%20periodic%20bump" \
  -H "X-TrackerToken: $TOKEN" \
  -H "Content-Type: application/json" | jq length)

echo "We found '$stories_count' stories in the last 3 weeks"

if [ $stories_count -eq 0 -a ${latest_commit_date} -lt ${three_weeks_ago} ]
then
  echo "Time for a new stemcell"
  echo "Periodic bump ($(date "+%b %e, %Y"))" > stemcell-trigger

  bosh-stemcells-ci/tasks/create-story.sh
else
  echo "Not yet time for a new stemcell"
fi
