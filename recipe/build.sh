#!/usr/bin/env bash

set -exuo pipefail

module='github.com/containers/podman'
export GOPATH="$( pwd )"
LICENSE_DIR="$( pwd )/license-files"

if [[ "${CONDA_BUILD_CROSS_COMPILATION:-0}" != "1" ]]; then
  (cd "src/${module}" && go test ./vendor/go.podman.io/storage/pkg/configfile)
fi

if [[ "$target_platform" == "osx-arm64" || "$target_platform" == "osx-64" ]]; then
  make -C "src/${module}" podman-remote
  # install.remote also tries to install podman-mac-helper which is not built;
  # install the remote binary manually and use separate targets for the rest.
  # This has to happen before podman-remote-darwin-docs, which rebuilds
  # bin/darwin/podman for the build machine (x86_64 for osx-arm64).
  install -d -m 755 "${PREFIX}/bin"
  install -m 755 "src/${module}/bin/darwin/podman" "${PREFIX}/bin/podman"
  make -C "src/${module}" podman-remote-darwin-docs
  make -C "src/${module}" \
    install.man install.completions \
    ETCDIR="${PREFIX}/etc"
  go version -m "${PREFIX}/bin/podman" | grep "GOARCH=${GOARCH}$"
else
  make -C "src/${module}" all
  make -C "src/${module}" \
    install install.completions \
    ETCDIR="${PREFIX}/etc"
  # Keep file/k8s-file defaults despite the systemd build tag, see the file.
  install -D -m 644 "${RECIPE_DIR}/10-conda-forge.conf" \
    "${PREFIX}/etc/containers/containers.conf.d/10-conda-forge.conf"
fi

cd "./src/${module}"
if [[ "$target_platform" == "osx-arm64" || "$target_platform" == "osx-64" ]]; then
  GOFLAGS="-tags=remote,exclude_graphdriver_btrfs,containers_image_openpgp" \
    go-licenses save ./cmd/podman/ --save_path="$LICENSE_DIR"
else
  go-licenses save ./cmd/podman/ --save_path="$LICENSE_DIR"
fi
