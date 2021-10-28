#! /usr/bin/env bash

module='github.com/containers/podman'
export GOPATH="$( pwd )"


make -C "src/${module}" \
  install install.completions \
  ETCDIR="${PREFIX}/etc" \


go-licenses save ./src/github.com/containers/podman/cmd --save_path=./license-files
