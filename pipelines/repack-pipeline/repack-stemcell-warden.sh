#!/bin/bash

set -eu
set -o pipefail

cat version/number | sed 's/\.0$//;s/\.0$//' > version-number/number # For metalink to update the right directory

stemcell=$PWD/stemcell/*.tgz
stemcell_version=$(cat $PWD/version-number/number)
path=$PWD/bosh-linux-stemcell-builder/scripts/repack-helpers
stemcell_path=$($path/extract-stemcell.sh $stemcell)

image_path=$(echo $stemcell_path | \
  $path/extract-image.sh | \
  $path/update-file.sh $PWD/bosh-agent/*-linux-amd64 /var/vcap/bosh/bin/bosh-agent | \
  $path/prepare-files-image.sh)

output_stemcell=$($path/pack-stemcell.sh $stemcell_path $image_path $stemcell_version)
cp $output_stemcell/stemcell.tgz repacked-stemcell/$(basename $stemcell)
