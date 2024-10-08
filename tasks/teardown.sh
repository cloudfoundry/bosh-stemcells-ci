#!/usr/bin/env bash

set -e

mv director-state/* .
mv director-state/.bosh $HOME/

export BOSH_ENVIRONMENT=`bosh int director-creds.yml --path /internal_ip`
export BOSH_CA_CERT=`bosh int director-creds.yml --path /director_ssl/ca`
export BOSH_CLIENT=admin
export BOSH_CLIENT_SECRET=`bosh int director-creds.yml --path /admin_password`

bosh deployments --column name | xargs -n1 -I % "bosh" -n -d % delete-deployment
bosh clean-up -n --all
bosh delete-env director.yml -l director-creds.yml
