#!/usr/bin/env bash
set -ex
cd candidate-aws-light-stemcell
tar -xzf *.tgz stemcell.MF
OS=$( cat stemcell.MF | grep operating_system | cut -f2 -d: | tr -d ' ')
#IGNORE gov and china stemcells. these are in a different account
AMI_LIST=$(cat stemcell.MF | grep ami- | tr -d ' '| grep -v 'gov-\|cn-')
VERSION=$(cat stemcell.MF | grep "^version" | cut -f2 -d: | tr -d ' ' | tr -d "'")
for AMI_LINE in $AMI_LIST; do
  AMI_REGION=$(echo $AMI_LINE | cut -f1 -d:)
  AMI_ID=$(echo $AMI_LINE | cut -f2 -d:)

  TAGS="[
    { \"Key\": \"published\", \"Value\": \"true\" },
    { \"Key\": \"name\"     , \"Value\": \"$OS-$VERSION\" },
    { \"Key\": \"distro\"   , \"Value\": \"$OS\" },
    { \"Key\": \"version\"  , \"Value\": \"$VERSION\" }
  ]"

  aws ec2 create-tags --resources "$AMI_ID" --region "$AMI_REGION" --tags "$TAGS"
done