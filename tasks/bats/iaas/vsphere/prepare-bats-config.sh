#!/bin/bash

set -e

manifest_path() { bosh int director-state/director.yml --path="$1" ; }
creds_path() { bosh int director-state/director-creds.yml --path="$1" ; }

director_ip=$( manifest_path /instance_groups/name=bosh/networks/name=default/static_ips/0 )
gateway_username=$( manifest_path "/instance_groups/0/jobs/name=user_add/properties/users/0/name" )
ssh_private_key=$( creds_path /jumpbox_ssh/private_key | sed 's/$/\\n/' | tr -d '\n' )

cat > bats-config/bats.env <<EOF
export BOSH_ENVIRONMENT="${director_ip}"
export BOSH_CLIENT="admin"
export BOSH_CLIENT_SECRET="$( creds_path /admin_password )"
export BOSH_CA_CERT="$( creds_path /director_ssl/ca )"

private_key_path=\$(mktemp)
echo -e "${ssh_private_key}" > \${private_key_path}

export BOSH_ALL_PROXY="ssh+socks5://${gateway_username}@${director_ip}:22?private-key=\${private_key_path}"

export BAT_INFRASTRUCTURE=vsphere

export BAT_RSPEC_FLAGS="--tag ~vip_networking --tag ~dynamic_networking --tag ~root_partition --tag ~raw_ephemeral_storage --tag ~skip_centos"
EOF

export VARS_DATACENTERS="$(bosh int director-state/director.yml --path="/instance_groups/name=bosh/properties/vcenter/datacenters" 2>/dev/null)"

cat > interpolate.yml <<EOF
---
cpi: vsphere
properties:
  pool_size: 1
  instances: 1
  second_static_ip: ((network1.staticIP-2))
  datacenters: ((DATACENTERS))
  dns: ((dns))
  ssh_gateway:
    host: "${director_ip}"
    username: "${gateway_username}"
  ssh_key_pair:
    public_key: "$( creds_path /jumpbox_ssh/public_key )"
    private_key: "${ssh_private_key}"
  stemcell:
    name: ((stemcell_name))
    version: latest
  networks:
    - name: static
      type: manual
      static_ip: ((network1.staticIP-1))
      cidr: ((network1.vCenterCIDR))
      reserved: ((network1.reservedRange))
      static: ((network1.staticRange))
      gateway: ((network1.vCenterGateway))
      vlan: ((network1.vCenterVLAN))
    - name: second
      type: manual
      static_ip: ((network2.staticIP-1))
      cidr: ((network2.vCenterCIDR))
      reserved: ((network2.reservedRange))
      static: ((network2.staticRange))
      gateway: ((network2.vCenterGateway))
      vlan: ((network2.vCenterVLAN))
EOF

bosh interpolate \
 --vars-file environment/metadata \
 --vars-env VARS \
 -v "stemcell_name=$STEMCELL_NAME" \
 interpolate.yml \
 > bats-config/bats-config.yml
