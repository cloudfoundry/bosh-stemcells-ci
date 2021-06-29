#!/bin/bash

set -eu

: ${BUCKET_NAME:?}
: ${STEMCELL_BUCKET_PATH:?} # used to check if current stemcell already exists

stemcell_url() {
  resource="/${STEMCELL_BUCKET_PATH}/${light_stemcell_name}"

  if [ ! -z "$AWS_ACCESS_KEY_ID" ]; then
    expires=$(date +%s)
    expires=$((expires + 30))

    string_to_sign="HEAD\n\n\n${expires}\n${resource}"
    signature=$(echo -en "$string_to_sign" | openssl sha1 -hmac ${AWS_SECRET_ACCESS_KEY} -binary | base64)
    signature=$(python -c "import urllib; print urllib.quote_plus('${signature}')")
    echo -n "https://${S3_API_ENDPOINT}${resource}?AWSAccessKeyId=${AWS_ACCESS_KEY_ID}&Expires=${expires}&Signature=${signature}"
  else
    echo -n "https://${S3_API_ENDPOINT}${resource}"
  fi
}

# inputs
bosh_stemcells_ci="$PWD/bosh-stemcells-ci/tasks/light-google"
stemcell_dir="$PWD/stemcell"

# outputs
raw_stemcell_dir="$PWD/raw-stemcell"

echo "Creating light stemcell..."

salt=$(date +%s)
original_stemcell="$(echo ${stemcell_dir}/*.tgz)"
original_stemcell_name="$(basename "${original_stemcell}")"
raw_stemcell_name="$(basename "${original_stemcell}" .tgz)-raw-$salt.tar.gz"
light_stemcell_name="light-${original_stemcell_name}"

echo "Using raw stemcell name: $raw_stemcell_name"

light_stemcell_url="$(stemcell_url)"
set +e
wget --spider "$light_stemcell_url"
if [[ "$?" == "0" ]]; then
  echo "Google light stemcell '$light_stemcell_name' already exists!"
  echo "You can download here: $light_stemcell_url"
  exit 1
fi
set -e

mkdir working_dir
pushd working_dir
  tar xvf "${original_stemcell}"

  raw_stemcell_path="${raw_stemcell_dir}/${raw_stemcell_name}"
  mv image "${raw_stemcell_path}"
popd
