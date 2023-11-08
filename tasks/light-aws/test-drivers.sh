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
: ${ami_fixture_id:?must be set}
: ${existing_volume_id:?must be set}
: ${existing_snapshot_id:?must be set}
: ${uploaded_machine_image_url:?must be set}
: ${kms_key_id:?must be set}

: ${uploaded_machine_image_format:=RAW}

# US Regions
export AWS_ACCESS_KEY_ID=$access_key
export AWS_SECRET_ACCESS_KEY=$secret_key
export AWS_BUCKET_NAME=$bucket_name
export AWS_REGION=$region
export AWS_DESTINATION_REGION=${copy_region}
export AWS_KMS_KEY_ID=${kms_key_id}

# Fixtures
export S3_MACHINE_IMAGE_URL=${uploaded_machine_image_url}
export S3_MACHINE_IMAGE_FORMAT=${uploaded_machine_image_format}
export EBS_VOLUME_ID=${existing_volume_id}
export EBS_SNAPSHOT_ID=${existing_snapshot_id}
export AMI_FIXTURE_ID=${ami_fixture_id}

echo "Downloading machine image"
export MACHINE_IMAGE_PATH=${tmp_dir}/image.iso
export MACHINE_IMAGE_FORMAT="RAW"
wget -O ${MACHINE_IMAGE_PATH} http://tinycorelinux.net/7.x/x86_64/archive/7.1/TinyCorePure64-7.1.iso

echo "Running driver tests"

pushd builder-src > /dev/null
  # Run all driver specs in parallel to reduce test time
  spec_count="$(grep "It(" -r driver | wc -l)"
  ginkgo -nodes ${spec_count} -r driver
popd
