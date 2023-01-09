#!/bin/bash

set -eu

TASK_DIR=$PWD

cd bosh-linux-stemcell-builder

function check_param() {
  local name=$1
  local value=$(eval echo '$'$name)
  if [ "$value" == 'replace-me' ]; then
    echo "environment variable $name must be set"
    exit 1
  fi
}
check_param OPERATING_SYSTEM_NAME
check_param OPERATING_SYSTEM_VERSION

OS_IMAGE_NAME=$OPERATING_SYSTEM_NAME-$OPERATING_SYSTEM_VERSION
OS_IMAGE=$TASK_DIR/os-image/$OS_IMAGE_NAME.tgz

sudo chown -R ubuntu .
sudo chown -R ubuntu:ubuntu /mnt
sudo chmod u+s $(which sudo)
sudo --preserve-env --set-home --user ubuntu -- /bin/bash --login -i <<SUDO
case $OPERATING_SYSTEM_VERSION
in
# Because of the difference in build environments between Xenial and other Ubuntu stemcell lines (currently only Jammy)
# we must run 'bundle install' as the root user for it to function correctly.
"xenial")
    sudo bundle install --local
    ;;
*)
    bundle install --local
    ;;
esac
    bundle exec rake stemcell:build_os_image[$OPERATING_SYSTEM_NAME,$OPERATING_SYSTEM_VERSION,$OS_IMAGE]
SUDO
