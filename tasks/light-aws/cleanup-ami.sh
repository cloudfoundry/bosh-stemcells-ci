#!/bin/bash

set -e

export AWS_ACCESS_KEY_ID=$ami_access_key
export AWS_SECRET_ACCESS_KEY=$ami_secret_key
export AWS_DEFAULT_REGION=$ami_region

: ${ami_older_than_days:?}
: ${ami_keep_latest:?}
: ${os_name:?}

__PASTDUE=$(date --date="$ami_older_than_days days ago" +"%Y-%m-%d")

ami_destinations="$(aws ec2 describe-regions --output text --query "Regions[?RegionName][].RegionName")"

for region in $ami_destinations; do

    # 'ami_ids' array should be orderered by creation date
    ami_list=$(aws ec2 describe-images \
            --owners self \
            --output json \
            --region $region \
            --filters "Name=name,Values=BOSH*" "Name=tag:published,Values=false" "Name=tag:distro,Values=$os_name" \
            --query 'sort_by(Images,&CreationDate)[?CreationDate<`'"$__PASTDUE"'`].{ImageId: ImageId, date:CreationDate, SnapshotId: BlockDeviceMappings[0].Ebs.SnapshotId,Version: Tags[?Key==`name`]|[0].Value}' | jq 'reverse | del(.[env.ami_keep_latest|tonumber])')

    # 'ami_list' is a json array of objects, each object is an ami and its snapshot
    for row in $(echo "${ami_list}" | jq -r '.[] | @base64'); do
      _jq() {
        echo ${row} | base64 --decode | jq -r ${1}
        }
      echo "
      ===============================================
      Cleaning up Ami and its snashots in $region
      Ami id:        $(_jq '.ImageId')
      Version:       $(_jq '.Version')
      Creation data: $(_jq '.date')
      Snapshot id:   $(_jq '.SnapshotId')
      "

      aws ec2 deregister-image \
        --image-id $(_jq '.ImageId') \
        --region $region

      aws ec2 delete-snapshot \
        --snapshot-id $(_jq '.SnapshotId') \
        --region $region
    done

done
