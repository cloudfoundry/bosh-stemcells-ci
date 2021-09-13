#!/usr/bin/env bash

set -e

source /etc/profile.d/chruby.sh
chruby ruby

function fromEnvironment() {
  local key="$1"
  local environment=environment/metadata
  cat $environment | jq -r "$key"
}

cat > director-creds.yml <<EOF
internal_ip: $(fromEnvironment '.directorIP')
EOF

if [ -d nimbus-vcenter-vars ]
then
  cp nimbus-vcenter-vars/nimbus-vcenter-vars.yml director-vars.yml
else
  cat > director-vars.yml <<EOF
vcenter_ip: "${VCENTER_IP}"
vcenter_user: "${VCENTER_USER}"
vcenter_password: "${VCENTER_PASSWORD}"
vcenter_cluster: "${VCENTER_CLUSTER}"
vcenter_dc: "${VCENTER_DC}"
vcenter_ds: "${VCENTER_DS}"
vcenter_rp: "${VCENTER_RP}"
vcenter_disks: BOSH-STEMCELL-CI-DISKS
vcenter_templates: BOSH-STEMCELL-CI-TEMPLATES
vcenter_vms: BOSH-STEMCELL-CI-VMS
EOF
fi

cat > network-variables.yml <<EOF
director_name: stemcell-smoke-tests-director
internal_cidr: $(fromEnvironment '.network1.vCenterCIDR')
internal_gw: $(fromEnvironment '.network1.vCenterGateway')
network_name: $(fromEnvironment '.network1.vCenterVLAN')
reserved_range: [$(fromEnvironment '.network1.reservedRange')]
internal_dns: $(fromEnvironment '.dns')
internal_ntp: $(fromEnvironment '.ntp')
EOF

export bosh_cli=$(realpath bosh-cli/*bosh-cli-*)
chmod +x $bosh_cli

echo "
# Temporary release https://github.com/cloudfoundry/bosh-vsphere-cpi-release/pull/303
# to resolve BATS Reading persistent disk settings: Persistent disk with volume id 'disk-xx' could not be found
- type: replace
  path: /releases/name=bosh-vsphere-cpi/url
  value: https://storage.googleapis.com/bosh-ecosystem-concourse/release.tgz

- type: replace
  path: /releases/name=bosh-vsphere-cpi/version
  value: 68+dev.2

- type: replace
  path: /releases/name=bosh-vsphere-cpi/sha1
  value: b245c32e30dcf8574a8e0fe8274d74f44743a969
" > tmp-cpi-ops.yml

$bosh_cli interpolate bosh-deployment/bosh.yml \
  -o bosh-deployment/vsphere/cpi.yml \
  -o tmp-cpi-ops.yml \
  -o bosh-deployment/vsphere/resource-pool.yml \
  -o bosh-deployment/jumpbox-user.yml \
  -o bosh-deployment/misc/ntp.yml \
  -o bosh-deployment/misc/dns.yml \
  --vars-store director-creds.yml \
  --vars-file director-vars.yml \
  --vars-file network-variables.yml > director.yml

set +e
$bosh_cli create-env director.yml -l director-creds.yml
deployed=$?
cp -r $HOME/.bosh director-state/
cp director.yml director-creds.yml director-state.json director-state/
if [ $deployed -ne 0 ]
then
  exit 1
fi
set -e

# occasionally we get a race where director process hasn't finished starting
# before nginx is reachable causing "Cannot talk to director..." messages.
sleep 10

export BOSH_ENVIRONMENT=`$bosh_cli int director-creds.yml --path /internal_ip`
export BOSH_CA_CERT=`$bosh_cli int director-creds.yml --path /director_ssl/ca`
export BOSH_CLIENT=admin
export BOSH_CLIENT_SECRET=`$bosh_cli int director-creds.yml --path /admin_password`

$bosh_cli -n update-cloud-config bosh-deployment/vsphere/cloud-config.yml \
          --ops-file bosh-stemcells-ci/ops-files/reserve-ips.yml \
          --ops-file bosh-stemcells-ci/ops-files/resource-pool-cc.yml \
          --vars-file network-variables.yml \
          --vars-file director-vars.yml
