#!/bin/bash

set -exo pipefail

podman --help
podman --version

# We cannot really test podman's functionality here because we'd need to
# run it as root and/or in a build container with more capabilities.
# Instead let's at least see if it read the config from containers-common.
# NOTE: This does not test if registries.conf is used because the program
#       terminates before reading the file (if built rootless in container).

# Skip test for linux-aarch64 or linux-ppc64lev due to namespace restrictions
if [ "${target_platform}" = "linux-aarch64" ] || [ "${target_platform}" = "linux-ppc64le" ] ; then
    echo "Skipping test on ${target_platform}"
    exit 0
fi

# Skip the local-daemon tests on macOS: the binary is podman-remote which
# has no local storage driver and requires a running podman machine/service.
if [[ "${target_platform}" == "osx-arm64" || "${target_platform}" == "osx-64" ]]; then
    # Minimal smoke-test for the remote client binary.
    podman --help
    podman --version
    echo "Skipping local daemon tests on ${target_platform} (podman-remote only)"
    exit 0
fi

# We use mktemp instead of a path in the test work directory to avoid
# "Error: the specified runroot is longer than 50 characters".
tmp="$( mktemp -d )"
trap 'cat "${tmp}/podman-info.txt" || true; rm -r "${tmp}" ; trap - EXIT ; exit' EXIT INT HUP

podman --log-level=debug --storage-driver=vfs \
    --root="${tmp}/root" --runroot="${tmp}/runroot" \
    info > "${tmp}/podman-info.txt" 2>&1

grep -F "seccompProfilePath: ${PREFIX}/share/containers/seccomp.json" "${tmp}/podman-info.txt"

# Helper binaries are searched in ${PREFIX}/{libexec/podman,lib/podman,bin}.
grep -F "path: ${PREFIX}/lib/podman/netavark" "${tmp}/podman-info.txt"
grep -F "path: ${PREFIX}/bin/aardvark-dns" "${tmp}/podman-info.txt"
test -x "${PREFIX}/libexec/podman/rootlessport"

# The containers.conf.d drop-in keeps the non-journald defaults (conmon from
# conda-forge has no journald support).
grep -F "logDriver: k8s-file" "${tmp}/podman-info.txt"
grep -F "eventLogger: file" "${tmp}/podman-info.txt"

# Without a running systemd (as in this build container) every systemd code
# path is disabled at runtime, so the defaults stay as in a non-systemd build.
if [ ! -d /run/systemd/system ]; then
    grep -F "cgroupManager: cgroupfs" "${tmp}/podman-info.txt"
fi

# Built with the `systemd` build tag: the journald events backend exists.
# (Without the tag this fails with "no support for journald logging".)
podman --events-backend=journald --storage-driver=vfs \
    --root="${tmp}/root" --runroot="${tmp}/runroot" \
    info > /dev/null

# The signature policy falls back to the one shipped by containers-common.
# (Only verifiable when the host has no /etc/containers/policy.json.)
if [ ! -e /etc/containers/policy.json ] && [ ! -e ~/.config/containers/policy.json ]; then
    podman --log-level=debug --storage-driver=vfs \
        --root="${tmp}/root" --runroot="${tmp}/runroot" \
        image trust show 2>&1 | grep -E "^all +default +accept"
fi
