#!/bin/bash

# Helper script to auto-patch the kernel from a given starting patch and new kernel version
# Run from the root of the repo
#
# Doesn't work for PVE kernels.

if [[ $# -ne 3 ]]; then
    echo "Usage: $0 <path-to-starting-patch> <new-kernel-version-path> <new-codename>"
    echo "    Example: $0 ubuntu/noble/hwe/6.8.0-90-generic ubuntu/noble/hwe/6.14.0-37-generic noble"
    exit 1
fi

ORIG_KERNEL_VERSION_FULL=$(basename "$1")
NEW_KERNEL_VERSION_FULL=$(basename "$2")
NEW_CODENAME="$3"
STARTING_PATCH_DIR="$1"
NEW_PATCH_DIR="$2"

if [[ ! -d "${STARTING_PATCH_DIR}" ]]; then
    echo "Starting patch directory ${STARTING_PATCH_DIR} does not exist!"
    exit 1
fi

if [[ -d "${NEW_PATCH_DIR}" ]]; then
    echo "New patch directory ${NEW_PATCH_DIR} already exists!"
    exit 1
fi

echo "Creating new patch directory ${NEW_PATCH_DIR} from ${STARTING_PATCH_DIR}..."
mkdir -p "${NEW_PATCH_DIR}"
cp -r "${STARTING_PATCH_DIR}/patches" "${NEW_PATCH_DIR}/"
sed -i "s/${ORIG_KERNEL_VERSION_FULL}/${NEW_KERNEL_VERSION_FULL}/g" "${NEW_PATCH_DIR}/patches/kvm-introvirt-hwe-${ORIG_KERNEL_VERSION_FULL}"

echo "Configuring for new kernel version ${NEW_KERNEL_VERSION_FULL}..."
KERNEL_VERSION_FULL=${NEW_KERNEL_VERSION_FULL} \
LSB_CODENAME=${NEW_CODENAME} \
./configure
ret=$?
if [[ $ret -ne 0 ]]; then
    echo "Configuration failed! See output above. Manual patching may be required."
    exit $ret
fi

echo "Updating quilt metadata..."
quilt rename kvm-introvirt-hwe-"${NEW_KERNEL_VERSION_FULL}"

echo "Patch created successfully in ${NEW_PATCH_DIR}"
echo "Update the quilt header, branch, and create a PR. Instructions in README.md"
exit 0