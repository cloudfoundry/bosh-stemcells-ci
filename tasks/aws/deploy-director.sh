#!/usr/bin/env bash

set -e

cat > director-creds.yml <<EOF
access_key_id:     ${AWS_ACCESS_KEY}
secret_access_key: ${AWS_SECRET_KEY}
EOF

cat > director-vars.yml <<EOF
region: ${AWS_REGION}
az:     ${AWS_AZ}
default_key_name: ${AWS_KEY_NAME}
default_security_groups: ${AWS_SECURITY_GROUPS}
tags: [${TAG}]
EOF

cat > network-variables.yml <<EOF
director_name: stemcell-smoke-tests-director
subnet_id: ${AWS_SUBNET_ID}
external_ip: ${EXTERNAL_IP}
internal_ip: ${INTERNAL_IP}
internal_cidr: ${INTERNAL_CIDR}
internal_gw: ${INTERNAL_GW}
reserved_range: [${RESERVED_RANGE}]
EOF

echo "${AWS_PRIVATE_KEY}" > bosh.pem

bosh interpolate bosh-deployment/bosh.yml \
  -o bosh-deployment/aws/cpi.yml \
  -o bosh-deployment/jumpbox-user.yml \
  -o bosh-deployment/external-ip-with-registry-not-recommended.yml \
  --vars-store director-creds.yml \
  --vars-file director-vars.yml \
  --var-file private_key=bosh.pem \
  --vars-file network-variables.yml > director.yml

set +e
bosh create-env director.yml -l director-creds.yml
deployed=$?

# hacky way to set bosh enviorment variable without modifying different tasks
echo "internal_ip: ${EXTERNAL_IP}" >> director-creds.yml

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

export BOSH_ENVIRONMENT=`bosh int director-creds.yml --path /internal_ip`
export BOSH_CA_CERT=`bosh int director-creds.yml --path /director_ssl/ca`
export BOSH_CLIENT=admin
export BOSH_CLIENT_SECRET=`bosh int director-creds.yml --path /admin_password`

bosh -n update-cloud-config bosh-deployment/aws/cloud-config.yml \
          --ops-file bosh-stemcells-ci/ops-files/reserve-ips.yml \
          --vars-file network-variables.yml \
          --vars-file director-vars.yml
