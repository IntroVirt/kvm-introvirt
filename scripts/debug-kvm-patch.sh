#!/bin/bash

# Helper to build an insert modified KVM kernel module for debugging

if [[ $# -ne 2 ]]; then
    echo "Usage: $0 <path-to-kernel-source> <path-to-signing-key-dir>"
    exit 1
fi

if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root"
    exit 1
fi

KERNEL_SRC=$1
SIGNING_KEY_DIR=$2

pushd "${KERNEL_SRC}" || { echo "Failed to change directory to ${KERNEL_SRC}"; exit 1; }

echo "Building KVM kernel modules"
make olddefconfig scripts prepare modules_prepare || { echo "Kernel preparation failed"; exit 1; }
make M=arch/x86/kvm/ || { echo "KVM module build failed"; exit 1; }

echo "Signing"
objcopy --remove-section .BTF ./arch/x86/kvm/kvm.ko
objcopy --remove-section .BTF ./arch/x86/kvm/kvm-intel.ko

./scripts/sign-file sha256 "${SIGNING_KEY_DIR}/MOK.priv" "${SIGNING_KEY_DIR}/MOK.der" ./arch/x86/kvm/kvm-intel.ko
./scripts/sign-file sha256 "${SIGNING_KEY_DIR}/MOK.priv" "${SIGNING_KEY_DIR}/MOK.der" ./arch/x86/kvm/kvm.ko

sudo rmmod kvm_intel kvm || echo "Modules not loaded, skipping rmmod"
sudo insmod ./arch/x86/kvm/kvm.ko || { echo "Failed to insert kvm.ko"; exit 1; }
sudo insmod ./arch/x86/kvm/kvm-intel.ko || { echo "Failed to insert kvm-intel.ko"; exit 1; }
popd || { echo "Failed to return to previous directory"; exit 1; }

echo "KVM kernel modules inserted successfully"

exit 0