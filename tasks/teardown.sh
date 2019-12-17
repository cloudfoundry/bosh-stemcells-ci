#!/usr/bin/env bash

set -e

source /etc/profile.d/chruby.sh
chruby ruby

mv director-state/* .
mv director-state/.bosh $HOME/

cp bosh-cli/alpha-bosh-cli-* /usr/local/bin/bosh-cli
chmod +x /usr/local/bin/bosh-cli

bosh-cli delete-env director.yml -l director-creds.yml
