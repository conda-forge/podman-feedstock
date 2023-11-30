#!/usr/bin/env bash

module='github.com/containers/podman'
export GOPATH="$( pwd )"
LICENSE_DIR="$( pwd )/license-files"

make -C "src/${module}" all
make -C "src/${module}" \
  install install.completions \
  ETCDIR="${PREFIX}/etc"

cd "./src/${module}"
go-licenses save ./cmd/podman/ --save_path="$LICENSE_DIR"
