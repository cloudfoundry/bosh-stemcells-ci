#!/usr/bin/env bash

set -e

mv director-state/* .
mv director-state/.bosh $HOME/

export bosh_cli=$(realpath bosh-cli/*bosh-cli-*)
chmod +x $bosh_cli

export BOSH_ENVIRONMENT=`$bosh_cli int director-creds.yml --path /internal_ip`
export BOSH_CA_CERT=`$bosh_cli int director-creds.yml --path /director_ssl/ca`
export BOSH_CLIENT=admin
export BOSH_CLIENT_SECRET=`$bosh_cli int director-creds.yml --path /admin_password`

$bosh_cli deployments --column name | xargs -n1 -I % "$bosh_cli" -n -d % delete-deployment
$bosh_cli clean-up -n --all
$bosh_cli delete-env director.yml -l director-creds.yml
