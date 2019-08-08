#!/bin/bash -eux

version=$( cat resolvconf-manager/.resource/version )

cp resolvconf-manager/.resource/metalink.meta4 \
	 bosh-linux-stemcell-builder/stemcell_builder/stages/bosh_go_agent/assets/resolvconf-manager.meta4

pushd bosh-linux-stemcell-builder
	if [ "$(git status --porcelain)" != "" ]; then
		git add -A
		git config --global user.email "ci@localhost"
		git config --global user.name "CI Bot"
		git commit -m "bump resolvconf-manager/$version"
	fi
popd
