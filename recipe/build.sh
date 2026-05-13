#!/usr/bin/env bash

set -exuo pipefail

module='github.com/containers/podman'
export GOPATH="$( pwd )"
LICENSE_DIR="$( pwd )/license-files"

if [[ "$target_platform" == "osx-arm64" || "$target_platform" == "osx-64" ]]; then
  make -C "src/${module}" podman-remote
  make -C "src/${module}" podman-remote-darwin-docs
  # install.remote also tries to install podman-mac-helper which is not built;
  # install the remote binary manually and use separate targets for the rest.
  install -d -m 755 "${PREFIX}/bin"
  install -m 755 "src/${module}/bin/darwin/podman" "${PREFIX}/bin/podman"
  make -C "src/${module}" \
    install.man install.completions \
    ETCDIR="${PREFIX}/etc"
else
  make -C "src/${module}" all
  make -C "src/${module}" \
    install install.completions \
    ETCDIR="${PREFIX}/etc"
fi

cd "./src/${module}"
if [[ "$target_platform" == "osx-arm64" || "$target_platform" == "osx-64" ]]; then
  GOFLAGS="-tags=remote,exclude_graphdriver_btrfs,containers_image_openpgp" \
    go-licenses save ./cmd/podman/ --save_path="$LICENSE_DIR"
else
  go-licenses save ./cmd/podman/ --save_path="$LICENSE_DIR"
fi
