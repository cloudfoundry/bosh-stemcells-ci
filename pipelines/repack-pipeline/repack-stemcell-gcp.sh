#!/bin/bash

set -eu
set -o pipefail
# This is copied from https://github.com/concourse/concourse/blob/3c070db8231294e4fd51b5e5c95700c7c8519a27/jobs/baggageclaim/templates/ba
# helps the /dev/mapper/control issue and lets us actually do scary things with the /dev mounts
# This allows us to create device maps from partition tables in image_create/apply.sh
function permit_device_control() {
  local devices_mount_info=$(cat /proc/self/cgroup | grep devices)

  local devices_subsytems=$(echo $devices_mount_info | cut -d: -f2)
  local devices_subdir=$(echo $devices_mount_info | cut -d: -f3)

  cgroup_dir=/mnt/tmp-todo-devices-cgroup

  if [ ! -e ${cgroup_dir} ]; then
    # mount our container's devices subsystem somewhere
    mkdir ${cgroup_dir}
  fi

  if ! mountpoint -q ${cgroup_dir}; then
    mount -t cgroup -o $devices_subsytems none ${cgroup_dir}
  fi

  # permit our cgroup to do everything with all devices
  # ignore failure in case something has already done this; echo appears to
  # return EINVAL, possibly because devices this affects are already in use
  echo a > ${cgroup_dir}${devices_subdir}/devices.allow || true
}

permit_device_control

# Also copied from baggageclaim_ctl.erb creates 64 loopback mappings. This fixes failures with losetup --show --find ${disk_image}
for i in $(seq 0 64); do
  if ! mknod -m 0660 /dev/loop$i b 7 $i; then
    break
  fi
done

cat version/number | sed 's/\.0$//;s/\.0$//' > version-number/number # For metalink to update the right directory

stemcell=$PWD/stemcell/*.tgz
stemcell_version=$(cat $PWD/version/version)
path=$PWD/bosh-linux-stemcell-builder/scripts/repack-helpers
stemcell_path=$($path/extract-stemcell.sh $stemcell)

image_path=$(echo $stemcell_path | \
  $path/extract-image.sh | \
  $path/mount-image.sh | \
  $path/update-file.sh $PWD/bosh-agent/*-linux-amd64 /var/vcap/bosh/bin/bosh-agent | \
  $path/unmount-image.sh | \
  $path/pack-raw-disk.sh)

output_stemcell=$($path/pack-stemcell.sh $stemcell_path $image_path $stemcell_version)
cp $output_stemcell/stemcell.tgz repacked-stemcell/$(basename $stemcell)
