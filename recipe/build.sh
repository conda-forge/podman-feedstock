#! /usr/bin/env bash

module='github.com/containers/podman'
export GOPATH="$( pwd )"


make -C "src/${module}" \
  install install.completions \
  ETCDIR="${PREFIX}/etc" \


tree -d

pwd

go-licenses save "src/${module}" --save_path=./license-files
