#!/bin/bash

set -e

manifest_path() { bosh-cli int director-state/director.yml --path="$1" ; }
creds_path() { bosh-cli int director-state/director-creds.yml --path="$1" ; }

cat > bats-config/bats.env <<EOF
export BOSH_ENVIRONMENT="$( manifest_path /instance_groups/name=bosh/networks/name=default/static_ips/0 2>/dev/null )"
export BOSH_CLIENT="admin"
export BOSH_CLIENT_SECRET="$( creds_path /admin_password )"
export BOSH_CA_CERT="$( creds_path /director_ssl/ca )"
export BOSH_GW_HOST="$( manifest_path /instance_groups/name=bosh/networks/name=default/static_ips/0 2>/dev/null )"
export BOSH_GW_USER="jumpbox"
export BAT_PRIVATE_KEY="$( creds_path /jumpbox_ssh/private_key )"

export BAT_DNS_HOST="$( manifest_path /instance_groups/name=bosh/networks/name=default/static_ips/0 2>/dev/null )"

export BAT_INFRASTRUCTURE=gcp
export BAT_NETWORKING=manual

export BAT_RSPEC_FLAGS="--tag ~vip_networking --tag ~dynamic_networking --tag ~root_partition --tag ~raw_ephemeral_storage --tag ~skip_centos"
EOF

export VARS_DATACENTERS="$(bosh-cli int director-state/director.yml --path="/instance_groups/name=bosh/properties/vcenter/datacenters" 2>/dev/null)"

cat > interpolate.yml <<EOF
---
cpi: gcp
properties:
  pool_size: 1
  instances: 1
  second_static_ip: ((network1.staticIP-2))
  stemcell:
    name: ((stemcell_name))
    version: latest
  networks:
    - name: default
      type: manual
      static_ip: 10.0.1.30 # Primary (private) IP assigned to the bat-release job vm (primary NIC), must be in the primary static range
      dns: [8.8.8.8]
      cloud_properties:
        network_name: ((network))
        subnetwork_name: ((subnetwork))
        ephemeral_external_ip: true
        tags: ((tags))
      cidr: 10.0.1.0/24
      reserved: ['10.0.1.2 - 10.0.1.9']
      static: ['10.0.1.10 - 10.0.1.30']
      gateway: 10.0.1.1
    - name: static
      type: manual
      static_ip: ((network1.staticIP-1))
      cidr: ((network1.vCenterCIDR))
      reserved: ((network1.reservedRange))
      static: ((network1.staticRange))
      gateway: ((network1.vCenterGateway))
      subnet: ((network1.vCenterVLAN))
    - name: second
      type: manual
      static_ip: ((network2.staticIP-1))
      cidr: ((network2.vCenterCIDR))
      reserved: ((network2.reservedRange))
      static: ((network2.staticRange))
      gateway: ((network2.vCenterGateway))
      vlan: ((network2.vCenterVLAN))
EOF

bosh-cli interpolate \
 --vars-file environment/metadata \
 --vars-env VARS \
 -v "stemcell_name=$STEMCELL_NAME" \
 interpolate.yml \
 > bats-config/bats-config.yml
