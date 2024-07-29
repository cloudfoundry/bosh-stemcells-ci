#!/bin/bash

set -euo pipefail

usn_json="${PWD}/usn-source/usn.json"
mkdir -p usn-log-in
touch usn-log-in/usn-log.json

jq -s --slurpfile new_usn $usn_json '. + $new_usn | unique_by(.url) | .[]' > usn-log-out/usn-log.json < usn-log-in/usn-log.json
