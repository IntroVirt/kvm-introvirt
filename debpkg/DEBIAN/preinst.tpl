#!/bin/bash

KERNEL_VERSION_FULL="<<<REPLACED_BY_CONFIGURE>>>"

RUNNING_KERNEL="$(uname -r)"
if [ "${RUNNING_KERNEL}" != "${KERNEL_VERSION_FULL}" ]; then
    echo "Modules are not for running kernel. Cannot install. Expected ${KERNEL_VERSION_FULL}."
    exit 1
fi

exit 0
