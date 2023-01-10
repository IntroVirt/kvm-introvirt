#!/bin/bash
set -eux

# Assumes $UBUNTU_KERNEL_VERSION is set
# e.g. UBUNTU_KERNEL_VERSION=ubuntu/focal/Ubuntu-5.4.0-113.127

INTROVIRT_PATCH_VERSION=$(cat VERSION)

if [[ ! -d .git ]]
then
    # Assume this is a package build
    # .build_vars and config.mk should already be generated
    . .build_vars
    if [[ ! -d kernel ]]
    then
        echo "Kernel directory is missing! Build will fail."
        exit 1
    fi
    if [[ ! -f config.mk ]]
    then
        echo "config.mk is missing! Build will fail."
        exit 1
    fi
    exit 0
fi

echo "${UBUNTU_KERNEL_VERSION}"
source ./scripts/ubuntu_vars.sh
PATCH_VERSION="$INTROVIRT_PATCH_VERSION"

apply_patches() {
    [ -d .pc ] && rm -r .pc

    export QUILT_PATCHES=patches/${DISTRO}/${DISTRO_RELEASE}/${KERNEL_VERSION_MAJOR}/${KERNEL_VERSION_FULL}
    quilt push -a
}

#TODO: We're assuming Ubuntu right now

if [[ ! -d kernel ]]
then
    # Clone the kernel into a working directory
    git clone --branch $KERNEL_TAG --depth 1 "https://git.launchpad.net/~ubuntu-kernel/ubuntu/+source/linux/+git/$DISTRO_RELEASE" kernel
    apply_patches
elif [[ -d kernel/.git ]]
then
    # Not a source package: The source package should not include kernel/.git
    pushd kernel

    # Verify clean state
    if output=$(git status --porcelain) && [ -z "$output" ]; then
        echo "kernel is clean and pointing to $(git rev-parse --short HEAD)"
    else
        echo "kernel is dirty, aborting..."
        exit 1
    fi

    git checkout $KERNEL_TAG

    popd

    apply_patches
fi

truncate -s0 .build_vars
echo "DISTRO=$DISTRO" >> .build_vars
echo "DISTRO_RELEASE=$DISTRO_RELEASE" >> .build_vars
echo "HWE_TAG=$HWE_TAG" >> .build_vars
echo "HWE_VERSION=$HWE_VERSION" >> .build_vars
echo "KERNEL_TAG=$KERNEL_TAG" >> .build_vars
echo "KERNEL_FLAVOR=$KERNEL_FLAVOR" >> .build_vars
echo "KERNEL_VERSION=$KERNEL_VERSION" >> .build_vars
echo "KERNEL_VERSION_FULL=$KERNEL_VERSION_FULL" >> .build_vars
echo "PATCH_VERSION=$PATCH_VERSION" >> .build_vars

truncate -s0 config.mk
echo "KERNEL_LIB_PATH = /lib/modules/$KERNEL_VERSION$KERNEL_FLAVOR" >> config.mk
echo "KERNEL_CONFIG_FILE = /boot/config-$KERNEL_VERSION$KERNEL_FLAVOR" >> config.mk
echo "KERNEL_SYMVERS_FILE = /usr/src/linux-headers-$KERNEL_VERSION$KERNEL_FLAVOR/Module.symvers" >> config.mk
echo 'INSTALL_DIR = $(DESTDIR)$(KERNEL_LIB_PATH)/updates/introvirt/' >> config.mk
echo "PATCH_VERSION = $PATCH_VERSION" >> config.mk
echo "KERNEL_VERSION_FULLER = $KERNEL_VERSION$KERNEL_FLAVOR" >> config.mk

rm -f debian/*.install debian/*.postinst debian/changelog debian/control debian/files

cp -f debian/kvm-introvirt.install.tpl "debian/kvm-introvirt-$KERNEL_VERSION$KERNEL_FLAVOR.install"
cp -f debian/kvm-introvirt.postinst.tpl "debian/kvm-introvirt-$KERNEL_VERSION$KERNEL_FLAVOR.postinst"
cp -f debian/changelog.tpl debian/changelog
cp -f debian/control.tpl debian/control

sed -i "s/@KERNEL_VERSION_FULL@/$KERNEL_VERSION_FULL/g" debian/changelog
sed -i "s/@PATCH_VERSION@/$PATCH_VERSION/g" debian/changelog
sed -i "s/@DISTRO_RELEASE@/${DISTRO_RELEASE}/g" debian/changelog

sed -i "s/@KERNEL_VERSION_KERNEL_FLAVOR@/$KERNEL_VERSION$KERNEL_FLAVOR/g" debian/control
sed -i "s/@KERNEL_VERSION_KERNEL_FLAVOR@/$KERNEL_VERSION$KERNEL_FLAVOR/g" debian/*.postinst
