#!/bin/bash -ex

REPO_ROOT="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )"
REPO_PARENT="$( cd "${REPO_ROOT}/.." && pwd )"

# we need sudo for our chroot operations in the shellout_types tests
apt install sudo

pushd "${REPO_PARENT}/bosh-linux-stemcell-builder"
  bundle install --local

  pushd bosh-stemcell
    bundle exec rspec spec/
    OS_IMAGE="$(readlink -f ../../os-image-tarball/*.tgz)" bundle exec rspec spec/ --tag shellout_types
  popd
popd
