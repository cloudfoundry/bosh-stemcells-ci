#!/bin/bash
set -euo pipefail
set -x

git clone bosh-linux-stemcell-builder bosh-linux-stemcell-builder-out

version=$( cat bosh-blobstore-cli/version )
sha256sum=$( sha256sum -b bosh-blobstore-cli/*cli* | awk '{print $1}' )

echo "${version}" > \
  "bosh-linux-stemcell-builder-out/stemcell_builder/stages/blobstore_clis/assets/bosh-blobstore-${BLOBSTORE_TYPE}.version"
echo "${sha256sum}" > \
  "bosh-linux-stemcell-builder-out/stemcell_builder/stages/blobstore_clis/assets/bosh-blobstore-${BLOBSTORE_TYPE}.sha256sum"

pushd bosh-linux-stemcell-builder-out
    if [ "$(git status --porcelain)" != "" ]; then
        git add -A
        git config --global user.email "ci@localhost"
        git config --global user.name "CI Bot"
        git commit -m "bump bosh-blobstore-${BLOBSTORE_TYPE}/${version}"
    fi
popd
