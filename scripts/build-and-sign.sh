#!/bin/bash

# Helper script to build a kvm-introvirt deb with signed .ko files.
# Will sign kernel modules with your own MOK key.
# Run from the root of the repo

set -e

if [[ $# -ne 1 ]]; then
    echo "Usage: $0 <path-to-signing-key-dir>"
    exit 1
fi

if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root"
    exit 1
fi

SIGNING_KEY_DIR="$1"

./configure
make -j"$(nproc)"

echo "Remove BTF section..."
objcopy --remove-section .BTF "ubuntu/$(lsb_release -sc)/hwe/$(uname -r)/kernel/arch/x86/kvm/kvm.ko"
objcopy --remove-section .BTF "ubuntu/$(lsb_release -sc)/hwe/$(uname -r)/kernel/arch/x86/kvm/kvm-intel.ko"
objcopy --remove-section .BTF "ubuntu/$(lsb_release -sc)/hwe/$(uname -r)/kernel/arch/x86/kvm/kvm-amd.ko"

echo "Signing kernel modules..."
"ubuntu/$(lsb_release -sc)/hwe/$(uname -r)/kernel/scripts/sign-file" \
    sha256 "${SIGNING_KEY_DIR}/MOK.priv" \
    "${SIGNING_KEY_DIR}/MOK.der" \
    "ubuntu/$(lsb_release -sc)/hwe/$(uname -r)/kernel/arch/x86/kvm/kvm-intel.ko"
"ubuntu/$(lsb_release -sc)/hwe/$(uname -r)/kernel/scripts/sign-file" \
    sha256 "${SIGNING_KEY_DIR}/MOK.priv" "${SIGNING_KEY_DIR}/MOK.der" \
    "ubuntu/$(lsb_release -sc)/hwe/$(uname -r)/kernel/arch/x86/kvm/kvm.ko"
"ubuntu/$(lsb_release -sc)/hwe/$(uname -r)/kernel/scripts/sign-file" \
    sha256 "${SIGNING_KEY_DIR}/MOK.priv" "${SIGNING_KEY_DIR}/MOK.der" \
    "ubuntu/$(lsb_release -sc)/hwe/$(uname -r)/kernel/arch/x86/kvm/kvm-amd.ko"

make package

echo "kvm-introvirt kernel modules signed and built into ./dist/kvm-introvirt-$(uname -r).$(lsb_release -sr)-X.X.X.deb"
