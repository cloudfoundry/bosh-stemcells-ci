#!/bin/bash

set -e

manifest_path() { bosh-cli int director-state/director.yml --path="$1" ; }
creds_path() { bosh-cli int director-state/director-creds.yml --path="$1" ; }

cat > bats-config/bats.env <<EOF
export BOSH_ENVIRONMENT="$( manifest_path /instance_groups/name=bosh/networks/name=default/static_ips/0 2>/dev/null )"
export BOSH_CLIENT="admin"
export BOSH_CLIENT_SECRET="$( creds_path /admin_password )"
export BOSH_CA_CERT="$( creds_path /director_ssl/ca )"
export BOSH_GW_HOST="$( manifest_path /instance_groups/name=bosh/networks/name=public/static_ips/0 2>/dev/null )"
export BOSH_GW_USER="jumpbox"
export BOSH_ALL_PROXY="ssh+socks5://\${BOSH_GW_USER}@\${BOSH_GW_HOST}:22?private-key=/tmp/bat_private_key"

export BAT_PRIVATE_KEY="$( creds_path /jumpbox_ssh/private_key )"

export BAT_DNS_HOST="$( manifest_path /instance_groups/name=bosh/networks/name=default/static_ips/0 2>/dev/null )"

export BAT_INFRASTRUCTURE=aws
export BAT_NETWORKING=manual

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
  stemcell:
    name: ((STEMCELL_NAME))
    version: latest
  networks:
    - name: default
      static_ip: ((STATIC_IP_DEFAULT))
      cidr: ((CIDR_DEFAULT))
      reserved: [((RESERVED_DEFAULT))]
      static: [((STATIC_DEFAULT))]
      gateway: ((GATEWAY_DEFAULT))
      subnet: ((SUBNETWORK_DEFAULT)) # VPC subnet
      security_groups: ((SECURITY_GROUPS)) # VPC security groups
  key_name: ((KEY_NAME)) # (optional) SSH keypair name, overrides the director's default_key_name setting
EOF

bosh-cli interpolate \
 --vars-env VARS \
 interpolate.yml \
 > bats-config/bats-config.yml
