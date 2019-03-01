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

find stemcells-index-output/$FROM_INDEX/$OS_NAME-$OS_VERSION/$VERSION -name *.meta4 \
  | xargs -n1 -- meta4 import-metalink --metalink="$meta4_path"

cd stemcells-index-output

git add -A
git config --global user.email "ci@localhost"
git config --global user.name "CI Bot"
git commit -m "$COMMIT_PREFIX: $OS_NAME-$OS_VERSION/$VERSION"

cd ..

#
# copy s3 objects into the public bucket
#

if [ "$FROM_BUCKET_NAME" == "$TO_BUCKET_NAME" ]; then
  echo "Skipping upload since buckets are the same..."
else
  for file in $COPY_KEYS ; do
    file="${file/\%s/$VERSION}"

    echo "$file"

    # occasionally this fails for unexpected reasons; retry a few times
    for i in {1..4}; do
      aws s3 cp "s3://$FROM_BUCKET_NAME/$file" "s3://$TO_BUCKET_NAME/$file" \
        && break \
        || sleep 5
    done

    echo ""
  done
fi

echo "${OS_NAME}-${OS_VERSION}/v${VERSION}" > version-tag/tag

echo "Done"
