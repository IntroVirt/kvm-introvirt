#!/bin/bash

# Helper to build and insert modified KVM kernel module for debugging
# Run from the root of the repo

if [[ $# -ne 2 ]]; then
    echo "Usage: $0 <path-to-kernel-source> <path-to-signing-key-dir>"
    exit 1
fi

if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root"
    exit 1
fi

# Default to 0 if not set.
# 0 = no tracing
# 1 = trace hypercalls and invlpg events
# 2 = trace single step and exception events (and above)
# 3 = trace fast syscall and fast syscall return events (and above)
_KVM_INTROVIRT_TRACE_EVENTS=${KVM_INTROVIRT_TRACE_EVENTS:=0}
echo "KVM introspection trace events level: ${_KVM_INTROVIRT_TRACE_EVENTS}"

KERNEL_SRC=$1
SIGNING_KEY_DIR=$2

if [[ ! -d "${KERNEL_SRC}" ]]; then
    echo "Kernel source directory ${KERNEL_SRC} does not exist!"
    exit 1
fi

if [[ ! -d "${SIGNING_KEY_DIR}" ]]; then
    echo "Signing key directory ${SIGNING_KEY_DIR} does not exist!"
    exit 1
fi

pushd "${KERNEL_SRC}" || { echo "Failed to change directory to ${KERNEL_SRC}"; exit 1; }

echo "Building KVM kernel modules"
make olddefconfig scripts prepare modules_prepare || { echo "Kernel preparation failed"; exit 1; }
make M=arch/x86/kvm/ clean
make M=arch/x86/kvm/ KCPPFLAGS="-DKVM_INTROVIRT_TRACE_EVENTS=${_KVM_INTROVIRT_TRACE_EVENTS}" || { echo "KVM module build failed"; exit 1; }

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