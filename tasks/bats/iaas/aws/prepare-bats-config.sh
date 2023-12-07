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

export BAT_INFRASTRUCTURE=aws

export BAT_RSPEC_FLAGS="--tag ~vip_networking --tag ~multiple_manual_networks --tag ~root_partition --tag ~raw_ephemeral_storage --tag ~skip_centos"
EOF

cat > interpolate.yml <<EOF
---
cpi: aws
properties:
  availability_zone: eu-central-1a
  instances: 1
  vip: ((VIP_DEFAULT)) # elastic ip for bat deployed VM
  second_static_ip: ((STATIC_IP_DEFAULT-2)) # Secondary (private) IP to use for reconfiguring networks, must be in the primary network & different from static_ip
  ssh_gateway:
    host: "${director_ip}"
    username: "${gateway_username}"
  ssh_key_pair:
    public_key: "$( creds_path /jumpbox_ssh/public_key )"
    private_key: "${ssh_private_key}"
  stemcell:
    name: ((STEMCELL_NAME))
    version: latest
  networks:
    - name: default
      type: manual
      static_ip: ((STATIC_IP_DEFAULT))
      cidr: ((CIDR_DEFAULT))
      reserved: ((RESERVED_DEFAULT))
      static: [((STATIC_DEFAULT))]
      gateway: ((GATEWAY_DEFAULT))
      subnet: ((SUBNETWORK_DEFAULT)) # VPC subnet
      security_groups: ((SECURITY_GROUPS)) # VPC security groups
  key_name: ((KEY_NAME)) # (optional) SSH keypair name, overrides the director's default_key_name setting
EOF

bosh interpolate \
 --vars-env VARS \
 interpolate.yml \
 > bats-config/bats-config.yml
