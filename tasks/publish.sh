#!/bin/bash

set -e
set -u

export VERSION=$( cat version/number | sed 's/\.0$//;s/\.0$//' )

#
# merge all stemcell files into a single metalink for publishing
#

git clone stemcells-index stemcells-index-output

meta4_path=$PWD/stemcells-index-output/$TO_INDEX/$OS_NAME-$OS_VERSION/$VERSION/stemcells.meta4

mkdir -p "$( dirname "$meta4_path" )"
meta4 create --metalink="$meta4_path"

find stemcells-index-output/$FROM_INDEX/$OS_NAME-$OS_VERSION/$VERSION -name "*.meta4" \
  | xargs -n1 -- meta4 import-metalink --metalink="$meta4_path"

# Import stemcell-trigger
mkdir -p stemcell-trigger
touch stemcell-trigger/stemcell-trigger

meta4 import-file --metalink="$meta4_path" --version="$VERSION" "stemcell-trigger/stemcell-trigger"
meta4 file-set-url --metalink="$meta4_path" --file="stemcell-trigger" "https://${S3_API_ENDPOINT}/${TO_BUCKET_NAME}/stemcell-trigger-${VERSION}"

cd stemcells-index-output

git add -A
git config --global user.email "ci@localhost"
git config --global user.name "CI Bot"
git commit -m "$COMMIT_PREFIX: $OS_NAME-$OS_VERSION/$VERSION"

cd ..

#
# copy s3 objects into the public bucket
#
#TODO: use gcp or use aws and use google s3 url s3://storage.googleapis.com/$FROM_BUCKET_NAME

if [ -n "${AWS_ROLE_ARN}" ]; then
  aws configure --profile creds_account set aws_access_key_id "${AWS_ACCESS_KEY_ID}"
  aws configure --profile creds_account set aws_secret_access_key "${AWS_SECRET_ACCESS_KEY}"
  aws configure --profile resource_account set source_profile "creds_account"
  aws configure --profile resource_account set role_arn "${AWS_ROLE_ARN}"
  aws configure --profile resource_account set region "${AWS_DEFAULT_REGION}"
  unset AWS_ACCESS_KEY_ID
  unset AWS_SECRET_ACCESS_KEY
  export AWS_PROFILE=resource_account
fi

if [ "$FROM_BUCKET_NAME" == "$TO_BUCKET_NAME" ]; then
  echo "Skipping upload since buckets are the same..."
else
  for file in $COPY_KEYS ; do
    file="${file/\%s/$VERSION}"

    echo "$file"

    # occasionally this fails for unexpected reasons; retry a few times
    for i in {1..4}; do
      aws --endpoint-url=${AWS_ENDPOINT} s3 cp "s3://$FROM_BUCKET_NAME/$file" "s3://$TO_BUCKET_NAME/$file" \
        && break \
        || sleep 5
    done

    echo ""
  done
fi

aws --endpoint-url=${AWS_ENDPOINT} s3 cp stemcell-trigger/stemcell-trigger "s3://${TO_BUCKET_NAME}/stemcell-trigger-${VERSION}"

echo "${OS_NAME}-${OS_VERSION}/v${VERSION}" > version-tag/tag

echo "Done"
