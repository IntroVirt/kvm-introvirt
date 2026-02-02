#!/bin/bash

# Helper script to download kernel source and apply the quilt patch for development
# Run from the root of the repo
#
# For PVE, run with LSB_RELEASE set to something for PVE (e.g. "pve-8.4")

if [[ $# -ne 2 ]]; then
    echo "Usage: $0 <full-kernel-version> <codename>"
    echo "    Example: $0 6.8.0-90-generic noble"
    echo "    Example: $0 6.8.4-2-pve pve"
    exit 1
fi

KERNEL_VERSION="$1"
CODENAME="$2"

KERNEL_VERSION_FULL="${KERNEL_VERSION}" \
LSB_CODENAME="${CODENAME}" \
./configure

exit 0