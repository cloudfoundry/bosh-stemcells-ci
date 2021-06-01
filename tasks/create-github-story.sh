#!/bin/bash

set -euo pipefail

: ${TOKEN:?}
: ${COLUMN_ID:?}
: ${BRANCH:?}
: ${DESCRIPTION:?}

curl \
  -X POST \
  -H "Accept: application/vnd.github.inertia-preview+json" \
  -H "Authorization: token $TOKEN" \
  https://api.github.com/projects/columns/$COLUMN_ID/cards \
  -d @- << EOF 2>/dev/null | jq -r '.url'
{
  "note" : "_$(date +%Y-%0m-%0d)_ - stemcell ${DESCRIPTION} [**$BRANCH**]\n\nIt's time to build a new version of stemcells which include the latest upstream vulnerability fixes. The pipeline should have automatically triggered when this story was created to kick off that process. Detailed instructions on what to do to make a patch lives [here](https://github.com/pivotal-cf/bosh-team/blob/master/stemcells/flow-of-stemcell-pipelines.md#cutting-a-new-stemcell-patch)\\n\\nEnsure the OS image and subsequent stemcell builds finished successfully.\\n\\n**Acceptance Criteria**\\n\\n* A new version of the stemcell can be published from the pipeline."
}
EOF