#!/bin/bash

# Helper to build and insert modified KVM kernel module for debugging
# Run from the root of the repo

if [[ $# -ne 1 ]]; then
    echo "Usage: $0 <path-to-kernel-source> [path-to-signing-key-dir]"
    exit 1
fi

KERNEL_SRC=$1

if [[ $# -ne 2 ]]; then
    SIGNING_KEY_DIR=""
else
    SIGNING_KEY_DIR=$2
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

if [[ ! -d "${KERNEL_SRC}" ]]; then
    echo "Kernel source directory ${KERNEL_SRC} does not exist!"
    exit 1
fi

if [[ -n "${SIGNING_KEY_DIR}" && ! -d "${SIGNING_KEY_DIR}" ]]; then
    echo "Signing key directory ${SIGNING_KEY_DIR} does not exist!"
    exit 1
else
    echo "No signing key directory provided, will not sign the kernel modules"
fi

WHICH_MOD="kvm_intel"
WHICH_KO="kvm-intel.ko"
if grep -iq "amd" /proc/cpuinfo; then
    WHICH_MOD="kvm_amd"
    WHICH_KO="kvm-amd.ko"
fi

pushd "${KERNEL_SRC}" || { echo "Failed to change directory to ${KERNEL_SRC}"; exit 1; }

echo "Building KVM kernel modules"
make olddefconfig scripts prepare modules_prepare || { echo "Kernel preparation failed"; exit 1; }
make M=arch/x86/kvm/ clean
make M=arch/x86/kvm/ KCPPFLAGS="-DKVM_INTROVIRT_TRACE_EVENTS=${_KVM_INTROVIRT_TRACE_EVENTS}" || { echo "KVM module build failed"; exit 1; }

if [[ -n "${SIGNING_KEY_DIR}" ]]; then
    echo "Signing"
    objcopy --remove-section .BTF ./arch/x86/kvm/kvm.ko
    objcopy --remove-section .BTF ./arch/x86/kvm/kvm-intel.ko
    objcopy --remove-section .BTF ./arch/x86/kvm/kvm-amd.ko

    ./scripts/sign-file sha256 "${SIGNING_KEY_DIR}/MOK.priv" "${SIGNING_KEY_DIR}/MOK.der" ./arch/x86/kvm/kvm-intel.ko
    ./scripts/sign-file sha256 "${SIGNING_KEY_DIR}/MOK.priv" "${SIGNING_KEY_DIR}/MOK.der" ./arch/x86/kvm/kvm.ko
    ./scripts/sign-file sha256 "${SIGNING_KEY_DIR}/MOK.priv" "${SIGNING_KEY_DIR}/MOK.der" ./arch/x86/kvm/kvm-amd.ko
fi

sudo rmmod ${WHICH_MOD} kvm || echo "Modules not loaded, skipping rmmod"
sudo insmod ./arch/x86/kvm/kvm.ko || { echo "Failed to insert kvm.ko"; exit 1; }
sudo insmod ./arch/x86/kvm/${WHICH_KO} || { echo "Failed to insert ${WHICH_KO}"; exit 1; }
popd || { echo "Failed to return to previous directory"; exit 1; }

echo "KVM kernel modules inserted successfully"

exit 0