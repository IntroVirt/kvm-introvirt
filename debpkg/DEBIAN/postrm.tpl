#!/bin/bash

KERNEL_VERSION_FULL="<<<REPLACED_BY_CONFIGURE>>>"

WHICH_MOD="kvm_intel"
if grep -iq "amd" /proc/cpuinfo; then
    WHICH_MOD="kvm_amd"
fi

case "$1" in
    remove|purge)
        rmmod ${WHICH_MOD} kvm
        rm -rf "/lib/modules/${KERNEL_VERSION_FULL}/updates/introvirt/"
        depmod -a "${KERNEL_VERSION_FULL}"
        modprobe ${WHICH_MOD}
        ;;
    upgrade|failed-upgrade)
        # do nothing; new package's files are already in place
        ;;
    *)
        ;;
esac

exit 0
