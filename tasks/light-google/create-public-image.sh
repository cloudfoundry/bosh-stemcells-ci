#!/bin/bash

set -eu

: ${PROJECT_NAME:?}
: ${GCP_SERVICE_ACCOUNT_KEY:?}



# inputs
bosh_stemcells_ci="$PWD/bosh-stemcells-ci/tasks/light-google"
stemcell_dir="$PWD/stemcell"
uploaded_gcs_dir="$PWD/base-oss-google-ubuntu-stemcell"

# outputs
light_stemcell_dir="$PWD/light-stemcell"

echo "Creating light stemcell..."

set -e
original_stemcell="$(echo ${stemcell_dir}/*.tgz)"
original_stemcell_name="$(basename "${original_stemcell}")"
light_stemcell_name="light-${original_stemcell_name}"

raw_stemcell="$(echo ${uploaded_gcs_dir}/*.gz)"
raw_stemcell_filename="$(basename "${raw_stemcell}")"

raw_stemcell_uri="$(cat "${uploaded_gcs_dir}/url")"

image_name=$(echo "$raw_stemcell_filename" | sed -e 's/[^0-9a-zA-Z]/-/g' -e 's/-tar-gz$//' -e 's/-go-agent-raw//' -e 's/^bosh-//')

# authenticate with service account
echo ${GCP_SERVICE_ACCOUNT_KEY} | gcloud auth activate-service-account --key-file - --project ${PROJECT_NAME}

efi_flag=""
if [ "${EFI}" == "true" ]; then
  efi_flag=(--guest-os-features UEFI_COMPATIBLE)
fi

# create image
gcloud compute images create ${image_name} \
 --project=${PROJECT_NAME} \
 --source-uri=${raw_stemcell_uri} \
 "${efi_flag[@]}" \
 --storage-location=eu


gcloud compute images add-iam-policy-binding ${image_name} \
    --member='allAuthenticatedUsers' \
    --role='roles/compute.imageUser'

mkdir working_dir
pushd working_dir
# create final light stemcell
  tar xvf "${original_stemcell}"

  > image
  packaged_image_stemcell_sha1=$(sha1sum image | awk '{print $1}')

  cp stemcell.MF /tmp/stemcell.MF.tmp

  bosh int \
    -o "${bosh_stemcells_ci}/assets/public-image-stemcell-ops.yml" \
    -v "packaged_image_stemcell_sha1=$packaged_image_stemcell_sha1" \
    -v 'stemcell_formats=["google-light"]' \
    -v "image_url=https://www.googleapis.com/compute/v1/projects/${PROJECT_NAME}/global/images/${image_name}" \
    /tmp/stemcell.MF.tmp > stemcell.MF

  light_stemcell_path="${light_stemcell_dir}/${light_stemcell_name}"
  tar czvf "${light_stemcell_path}" *
popd
