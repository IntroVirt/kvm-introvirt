#!/bin/bash

KERNEL_VERSION_FULL="<<<REPLACED_BY_CONFIGURE>>>"

function check_module_loaded() {
    grep -q "$1 " /proc/modules
    return $?
}

function unload_module() {
    check_module_loaded $1
    if [ $? -eq 0 ]; then
        echo "Unloading $1..."
        rmmod $1
        RESULT=$?
        if [ $RESULT -ne 0 ]; then
            echo "Failed to unload $1"
        fi
        return $RESULT
    else
        echo "$1 not loaded"
        return 0
    fi
}

if [ "$1" = "configure" ] || [ "$1" = "abort-upgrade" ] || [ "$1" = "abort-deconfigure" ] || [ "$1" = "abort-remove" ] ; then
    if [ -e "/boot/System.map-${KERNEL_VERSION_FULL}" ]; then
        depmod -a -F "/boot/System.map-${KERNEL_VERSION_FULL}" "${KERNEL_VERSION_FULL}" || true
    fi
fi

RUNNING_KERNEL="$(uname -r)"
if [ "${RUNNING_KERNEL}" != "${KERNEL_VERSION_FULL}" ]; then
    echo "Modules are not for running kernel. Not reloading."
    exit 0
fi

#
# Try to reload the kernel modules
#
FAILED=0

unload_module "kvmgt"
unload_module "kvm_intel"
unload_module "kvm_amd"
if [ $? -eq 0 ]; then
    unload_module "kvm"
    if [ $? -ne 0 ]; then
        FAILED=1
    fi
else
    FAILED=1
fi

WHICH_MOD="kvm_intel"
if grep -iq "amd" /proc/cpuinfo; then
    WHICH_MOD="kvm_amd"
fi

if [ $FAILED -ne 0 ]; then
    echo "FAILED TO RELOAD KVM MODULES!!!"
    echo "Please shutdown your VMs and run 'sudo modprobe -r ${WHICH_MOD} kvm && sudo modprobe ${WHICH_MOD}'"
else
    echo "Loading ${WHICH_MOD} module"
    modprobe ${WHICH_MOD}
fi
