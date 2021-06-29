#!/usr/bin/env bash

set -e

my_dir="$( cd $(dirname $0) && pwd )"
source "${my_dir}/utils.sh"

tmp_dir="$(mktemp -d /tmp/stemcell_builder.XXXXXXX)"
trap '{ rm -rf ${tmpdir}; }' EXIT

: ${access_key:?must be set}
: ${secret_key:?must be set}
: ${bucket_name:?must be set}
: ${region:?must be set}
: ${copy_region:?must be set}
# : ${cn_access_key:?must be set}
# : ${cn_secret_key:?must be set}
# : ${cn_bucket_name:?must be set}
# : ${cn_region:?must be set}

# US Regions
export AWS_ACCESS_KEY_ID=$access_key
export AWS_SECRET_ACCESS_KEY=$secret_key
export AWS_BUCKET_NAME=$bucket_name
export AWS_REGION=$region
export AWS_DESTINATION_REGION=${copy_region}

# # China Region
# export AWS_CN_ACCESS_KEY_ID=$cn_access_key
# export AWS_CN_SECRET_ACCESS_KEY=$cn_secret_key
# export AWS_CN_BUCKET_NAME=$cn_bucket_name
# export AWS_CN_REGION=$cn_region

echo "Downloading machine image"
export MACHINE_IMAGE_PATH=${tmp_dir}/image.iso
export MACHINE_IMAGE_FORMAT="RAW"
wget -O ${MACHINE_IMAGE_PATH} http://tinycorelinux.net/7.x/x86_64/archive/7.1/TinyCorePure64-7.1.iso

echo "Running integration tests"

pushd builder-src/src/light-stemcell-builder > /dev/null
  ginkgo -v -r integration
popd
