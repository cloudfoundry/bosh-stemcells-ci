#!/bin/bash

set -eux

set -o pipefail

root_dir=$PWD
version=$(cat stemcell-metalink/.resource/version | sed 's/\.0$//')

mkdir -p release-metadata
echo -n "${OS_NAME} ${OS_VERSION} v$version" > release-metadata/name
echo -n "${OS_NAME}-${OS_VERSION}/v$version" > release-metadata/tag

install_jq() {
  pushd $(mktemp -d)
    wget https://github.com/stedolan/jq/releases/download/jq-1.5/jq-linux64
    echo "c6b3a7d7d3e7b70c6f51b706a3b90bd01833846c54d32ca32f0027f00226ff6d  jq-linux64" > jq.txt
    shasum -c jq.txt
    chmod +x jq-linux64
    mv jq-linux64 /usr/bin/jq
  popd
}

install_jq

pushd bosh-linux-stemcell-builder
  bosh_agent_version=$(cat stemcell_builder/stages/bosh_go_agent/assets/bosh-agent-version)
  echo "## Metadata:" >> "${root_dir}/release-metadata/body"
  echo "**BOSH Agent Version**: ${bosh_agent_version}" >> "${root_dir}/release-metadata/body"
  if [[ "${OS_NAME}" == "ubuntu" ]]; then
    # Ensure URL for usn-log from metalink exists before attempting to download.
    touch usn-log.json
    if [[ -n "$(meta4 file-urls --metalink bosh-stemcell/image-metalinks/${BRANCH}/${OS_NAME}-${OS_VERSION}.meta4 --file usn-log.json)" ]]; then
      meta4 file-download --metalink "bosh-stemcell/image-metalinks/${BRANCH}/${OS_NAME}-${OS_VERSION}.meta4" --file usn-log.json usn-log.json --skip-hash-verification --skip-signature-verification
    fi

    echo "" >> "${root_dir}/release-metadata/body"
    echo "## USNs:" >> "${root_dir}/release-metadata/body"
    echo "$(${root_dir}/bosh-stemcells-ci/bin/format-usn-log usn-log.json)" >> "${root_dir}/release-metadata/body"
  fi
popd

echo "" > usn-log/usn-log.json
