#! /usr/bin/env bash

module='github.com/containers/podman'
export GOPATH="$( pwd )"


make -C "src/${module}" \
  install install.completions \
  ETCDIR="${PREFIX}/etc" \


tree -d

go-licenses save ./github.com/containers/podman --save_path=./license-files
