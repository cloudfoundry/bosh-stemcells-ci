#!/usr/bin/env bash

set -eu

bosh_cli=$(realpath bosh-cli/alpha-bosh-cli-*)
export bosh_cli
chmod +x "$bosh_cli"

state_path() { $bosh_cli int director-state/director.yml --path="$1" ; }

function get_bosh_environment {
  if [[ -z $(state_path /instance_groups/name=bosh/networks/name=public/static_ips/0 2>/dev/null) ]]; then
    state_path /instance_groups/name=bosh/networks/name=default/static_ips/0 2>/dev/null
  else
    state_path /instance_groups/name=bosh/networks/name=public/static_ips/0 2>/dev/null
  fi
}

BOSH_ENVIRONMENT=$(get_bosh_environment)
export BOSH_ENVIRONMENT
BOSH_CA_CERT=$("$bosh_cli" int director-state/director-creds.yml --path /director_ssl/ca)
export BOSH_CA_CERT
export BOSH_CLIENT=admin
BOSH_CLIENT_SECRET=$("$bosh_cli" int director-state/director-creds.yml --path /admin_password)
export BOSH_CLIENT_SECRET

set +e

"$bosh_cli" deployments --column name | xargs -n1 -I % "$bosh_cli" -n -d % delete-deployment
"$bosh_cli" clean-up -n --all
"$bosh_cli" delete-env -n director-state/director.yml -l director-state/director-creds.yml
