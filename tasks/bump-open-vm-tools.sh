#!/bin/bash
set -euo pipefail
set -x

git clone bosh-linux-stemcell-builder bosh-linux-stemcell-builder-out

pushd open-vm-tools
  url="https://github.com/vmware/open-vm-tools/releases/download/$(cat version)/$(ls open-vm-tools-*.tar.gz)"
  version=$(cat version)
  sha256sum=$(sha256sum -b open-vm-tools-*.tar.gz | awk '{print $1}')
popd

echo "${url}" > \
  "bosh-linux-stemcell-builder-out/stemcell_builder/stages/system_open_vm_tools/assets/open-vm-tools.url"
echo "${version}" > \
  "bosh-linux-stemcell-builder-out/stemcell_builder/stages/system_open_vm_tools/assets/open-vm-tools.version"
echo "${sha256sum}" > \
  "bosh-linux-stemcell-builder-out/stemcell_builder/stages/system_open_vm_tools/assets/open-vm-tools.sha256sum"

pushd bosh-linux-stemcell-builder-out
  if [ "$(git status --porcelain)" != "" ]; then
    git add -A
    git config --global user.email "ci@localhost"
    git config --global user.name "CI Bot"
    git commit -m "bump open-vm-tools-${version}"
  fi
popd
