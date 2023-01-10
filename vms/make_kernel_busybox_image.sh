#!/bin/bash
set -eux

DIR=$(realpath $( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )/..)

BUSYBOX_WORKDIR="/tmp/busybox"
BUSYBOX_CFG_PATH=$DIR/vms/busybox_1_32_1_static_config
BUSYBOX_VERSION="1.32.1"
MAKEPROCS=3

source "$DIR/vms/make_busybox.sh"
source "$DIR/vms/make_kernel.sh"

# # cleanup
# make -C $DIR/kernel/tools/testing/selftests/kvm clean

# Build tests
CFLAGS=" -static " make -C $DIR/kernel/tools/testing/selftests/kvm -j

# make initramfs busybox
mkdir -p $BUSYBOX_WORKDIR
make_busybox "$BUSYBOX_WORKDIR" "$BUSYBOX_CFG_PATH" "$BUSYBOX_VERSION" "$MAKEPROCS"
# Copy tests
rm -rf $BUSYBOX_WORKDIR/busybox_rootfs/bin/kvm_tests
mkdir $BUSYBOX_WORKDIR/busybox_rootfs/bin/kvm_tests
find ~/work/ivacadiana/workspace/kvm-introvirt/kernel/tools/testing/selftests/kvm/ -type f -executable -exec cp {} $BUSYBOX_WORKDIR/busybox_rootfs/bin/kvm_tests \;
make_initramfs "$DIR/kernel" "$BUSYBOX_WORKDIR/busybox_rootfs" "" ""

# make kernel
cp $DIR/vms/defconfig_initramfs $DIR/kernel/.config
make -C $DIR/kernel clean
make -C $DIR/kernel olddefconfig
make -C $DIR/kernel bzImage -j
