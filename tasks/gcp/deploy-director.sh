#!/usr/bin/env bash

set -e

cat > director-creds.yml <<EOF
internal_ip: ${INTERNAL_IP}
EOF

cat > director-vars.yml <<EOF
project_id: ${GCP_PROJECT_ID}
zone: ${GCP_ZONE}
preemptible: ${GCP_PREEMPTIBLE}
tags: [${TAG}]
default_vm_type: ${DEFAULT_VM_TYPE}
EOF

cat > default-vm-type-opsfile.yml <<EOF
---
- name: vm_types
  path: /vm_types/name=default/cloud_properties/machine_type
  type: replace
  value: (( default_vm_type ))
- name: vm_types
  path: /vm_types/name=large/cloud_properties/machine_type
  type: replace
  value: (( default_vm_type ))
EOF

cat > network-variables.yml <<EOF
director_name: stemcell-smoke-tests-director
internal_cidr: ${INTERNAL_CIDR}
internal_gw: ${INTERNAL_GW}
network:    ${GCP_NETWORK_NAME}
subnetwork: ${GCP_SUBNET_NAME}
reserved_range: [${RESERVED_RANGE}]
EOF

echo ${GCP_JSON_KEY} > gcp_creds.json

bosh interpolate bosh-deployment/bosh.yml \
  -o bosh-deployment/gcp/cpi.yml \
  -o bosh-deployment/jumpbox-user.yml \
  --vars-store director-creds.yml \
  --vars-file director-vars.yml \
  --var-file gcp_credentials_json=gcp_creds.json \
  --vars-file network-variables.yml > director.yml

set +e
bosh create-env director.yml -l director-creds.yml
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

export BOSH_ENVIRONMENT=`bosh int director-creds.yml --path /internal_ip`
export BOSH_CA_CERT=`bosh int director-creds.yml --path /director_ssl/ca`
export BOSH_CLIENT=admin
export BOSH_CLIENT_SECRET=`bosh int director-creds.yml --path /admin_password`

bosh -n update-cloud-config bosh-deployment/gcp/cloud-config.yml \
          --ops-file default-vm-type-opsfile.yml \
          --ops-file bosh-stemcells-ci/ops-files/reserve-ips.yml \
          --ops-file bosh-stemcells-ci/ops-files/disable-ephemeral-ip.yml \
          --vars-file network-variables.yml \
          --vars-file director-vars.yml
