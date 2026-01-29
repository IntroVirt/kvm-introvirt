#!/bin/bash

# Helper script to download kernel source and apply the quilt patch for development
# Assumes deb-src entries are in /etc/apt/sources.list or ubuntu.sources

if [[ $# -ne 1 ]]; then
    echo "Usage: $0 <patch/dir>"
    echo "    Example: $0 ubuntu/noble/hwe/6.8.0-90-generic"
    exit 1
fi

KERNEL_VERSION="$(basename "$1")"
PATCH_DIR="$1"

pushd "${PATCH_DIR}" > /dev/null || exit 1

if [[ ! -d "./kernel" ]]; then
    echo "Getting kernel source. This could take a bit..."

    # Figure out the name of the package
    FULL_VER=$(apt-cache policy linux-image-unsigned-"${KERNEL_VERSION}" | grep "Candidate:" | awk '{print $2}')
    if [[ -z "${FULL_VER}" || $? -ne 0 ]]; then
        echo "Could not find kernel package linux-image-unsigned-${KERNEL_VERSION}"
        popd > /dev/null || exit 1
        exit 1
    fi

    if ! apt-get source linux="${FULL_VER}"; then
        echo "Could not download kernel source for linux-image-unsigned-${KERNEL_VERSION}"
        echo "Possible this version isn't available anymore."
        echo "Available versions:"
        apt-cache showsrc linux | grep '^Version:'
        popd > /dev/null || exit 1
        exit 1
    fi
    mv linux*"$(echo "${KERNEL_VERSION}" | cut -d- -f 1)/" kernel
    rm -f linux*.dsc linux*.tar.gz linux*.diff.gz
    chmod +x kernel/scripts/*.sh
fi

if quilt unapplied; then
    # Apply patches
    if ! quilt push -a; then
        echo "Patch failed to apply. Use \"quilt push -a -f\" and then reconcile the *.rej files"
        echo "Then update the patch with \"quilt refresh\" followed by \"quilt pop -a\""
        echo "Make sure to \"quilt add <path>\" for any new files that may need to be patched before"
        echo "making any changes to those files."
        popd > /dev/null || exit 1
        exit 1
    fi
fi
popd > /dev/null || exit 1

exit 0