#!/usr/bin/env bash
set -eu -o pipefail
set -e

BOSH_BINARY_PATH=$(realpath "$(which bosh)")
BOSH_CA_CERT="$(bosh int director-state/director-creds.yml --path /director_ssl/ca)"
BOSH_CLIENT_SECRET="$(bosh int director-state/director-creds.yml --path /admin_password)"
BOSH_ENVIRONMENT="$(bosh int director-state/director-creds.yml --path /internal_ip)"
SYSLOG_RELEASE_PATH="$(realpath syslog-release/*.tgz)"
OS_CONF_RELEASE_PATH="$(realpath os-conf-release/*.tgz)"
STEMCELL_PATH="$(realpath stemcell/*.tgz)"
# Quote value since the bosh CLI YAML parses it which results in `0.40` becoming `0.4`
# shellcheck disable=SC2089
BOSH_stemcell_version="\"$(realpath stemcell/.resource/version | xargs -n 1 cat)\""

export BOSH_BINARY_PATH
export BOSH_CA_CERT
export BOSH_CLIENT="admin"
export BOSH_CLIENT_SECRET
export BOSH_ENVIRONMENT
export SYSLOG_RELEASE_PATH
export OS_CONF_RELEASE_PATH
export STEMCELL_PATH
export BOSH_stemcell_version

if bosh int director-state/director-creds.yml --path /jumpbox_ssh > /dev/null 2>&1 ; then
  jumpbox_private_key="$(mktemp)"
  bosh int director-state/director-creds.yml --path /jumpbox_ssh/private_key > "${jumpbox_private_key}"
  chmod 0600 "${jumpbox_private_key}"
  export BOSH_GW_PRIVATE_KEY="${jumpbox_private_key}"
  export BOSH_GW_USER="jumpbox"
  export BOSH_GW_HOST="${BOSH_ENVIRONMENT}"
fi

pushd bosh-linux-stemcell-builder/acceptance-tests
  # shellcheck disable=SC2154
  go run github.com/onsi/ginkgo/v2/ginkgo --skip-package vendor -r "${package}"
popd
