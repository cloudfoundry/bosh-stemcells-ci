#!/bin/bash -ex

source /etc/profile.d/chruby.sh
chruby ruby

pushd bosh-linux-stemcell-builder
  bundle install --local

  pushd bosh-stemcell
    bundle exec rspec spec/
    OS_IMAGE="$(readlink -f ../../os-image-tarball/*.tgz)" bundle exec rspec spec/ --tag shellout_types
  popd
popd
