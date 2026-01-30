#!/bin/bash

KERNEL_VERSION_FULL="<<<REPLACED_BY_CONFIGURE>>>"

WHICH_MOD="kvm_intel"
if grep -iq "amd" /proc/cpuinfo; then
    WHICH_MOD="kvm_amd"
fi

rmmod ${WHICH_MOD} kvm
rm -rf "/lib/modules/${KERNEL_VERSION_FULL}/updates/introvirt/"
depmod -a "${KERNEL_VERSION_FULL}"
modprobe ${WHICH_MOD}

exit 0
