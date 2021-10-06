#!/bin/bash -ex

# we need sudo for our chroot operations in the shellout_types tests
apt install sudo

pushd bosh-linux-stemcell-builder
  bundle install --local

  pushd bosh-stemcell
    bundle exec rspec spec/
    OS_IMAGE="$(readlink -f ../../os-image-tarball/*.tgz)" bundle exec rspec spec/ --tag shellout_types
  popd
popd
