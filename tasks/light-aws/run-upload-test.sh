#!/usr/bin/env bash

set -e

source director-state/director.env

pushd stemcell
  time bosh -n upload-stemcell *.tgz
popd

