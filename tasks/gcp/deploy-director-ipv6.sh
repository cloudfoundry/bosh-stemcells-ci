#!/usr/bin/env bash
set -e

source /etc/profile.d/chruby.sh
chruby ruby

cat > director-creds.yml <<EOF
internal_ip: ${INTERNAL_IP}
EOF

cat > director-vars.yml <<EOF
project_id: ${GCP_PROJECT_ID}
zone: ${GCP_ZONE}
tags: [${TAG}]
EOF

cat > network-vars.yml <<EOF
director_name: stemcell-smoke-tests-director
internal_cidr: ${INTERNAL_CIDR}
internal_gw: ${INTERNAL_GW}
network:    ${GCP_NETWORK_NAME}
subnetwork: ${GCP_SUBNET_NAME}

# second_network_name: $(fromEnvironment '.network1IPv6.vCenterVLAN')
# second_internal_gw: $(fromEnvironment '.network1IPv6.vCenterGateway')
# second_internal_cidr: $(fromEnvironment '.network1IPv6["vCenterCIDR"]')
# second_internal_ip: $(fromEnvironment '.network1IPv6["staticIP-1"]')
# internal_dns: $(fromEnvironment '.dns')
# internal_ntp: $(fromEnvironment '.ntp')
EOF

export bosh_cli=$(realpath bosh-cli/*bosh-cli-*)
chmod +x $bosh_cli

$bosh_cli interpolate bosh-deployment/bosh.yml \
  -o bosh-deployment/gcp/cpi.ym \
  -o bosh-deployment/jumpbox-user.yml \
  -o bosh-deployment/misc/ipv6/bosh.yml \
  -o bosh-deployment/misc/second-network.yml \
  # -o bosh-deployment/misc/ntp.yml \
  # -o bosh-deployment/misc/dns.yml \
  -o bosh-stemcells-ci/ops-files/ipv6-director.yml \
  --vars-store director-creds.yml \
  --vars-file director-vars.yml \
  --vars-file network-vars.yml > director.yml

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
          --ops-file bosh-stemcells-ci/ops-files/ipv6-cc.yml \
          --ops-file bosh-stemcells-ci/ops-files/resource-pool-cc.yml \
          --vars-file network-vars.yml \
          --vars-file director-vars.yml
