#!/usr/bin/env bash

set -e

source /etc/profile.d/chruby.sh
chruby ruby

cat > director-creds.yml <<EOF
access_key_id:     ${AWS_ACCESS_KEY}
secret_access_key: ${AWS_SECRET_KEY}
EOF

cat > director-vars.yml <<EOF
region: ${AWS_REGION}
az:     ${AWS_AZ}
default_key_name: ${AWS_KEY_NAME}
default_security_groups: [${AWS_SECURITY_GROUPS}]
tags: [${TAG}]
EOF

cat > network-variables.yml <<EOF
director_name: stemcell-smoke-tests-director
subnet_id: ${AWS_SUBNET_ID}
internal_ip: ${INTERNAL_IP}
internal_cidr: ${INTERNAL_CIDR}
internal_gw: ${INTERNAL_GW}
reserved_range: [${RESERVED_RANGE}]
EOF

echo ${AWS_PRIVATE_KEY} > bosh.pem

export bosh_cli=$(realpath bosh-cli/*bosh-cli-*)
chmod +x $bosh_cli

$bosh_cli interpolate bosh-deployment/bosh.yml \
  -o bosh-deployment/aws/cpi.yml \
  -o bosh-deployment/jumpbox-user.yml \
  --vars-store director-creds.yml \
  --vars-file director-vars.yml \
  --var-file private_key=bosh.pem \
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

$bosh_cli -n update-cloud-config bosh-deployment/aws/cloud-config.yml \
          --ops-file bosh-stemcells-ci/ops-files/reserve-ips.yml \
          --ops-file bosh-stemcells-ci/ops-files/disable-ephemeral-ip.yml \
          --vars-file network-variables.yml \
          --vars-file director-vars.yml
