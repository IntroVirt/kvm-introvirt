#!/bin/bash

KERNEL_VERSION_FULL="<<<REPLACED_BY_CONFIGURE>>>"

rmmod kvm-intel kvm
rm -rf "/lib/modules/${KERNEL_VERSION_FULL}/updates/introvirt/"
depmod -a "${KERNEL_VERSION_FULL}"
modprobe kvm-intel

exit 0
