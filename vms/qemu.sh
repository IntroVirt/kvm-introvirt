#!/usr/bin/env bash
set -eu

DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
BZIMAGE=$(realpath $DIR/../arch/x86/boot/bzImage)

[ ! -f $BZIMAGE ] && echo "Error: missing $BZIMAGE" && echo exit 1

# echo add-auto-load-safe-path $DIR/kernel/scripts/gdb/vmlinux-gdb.py >> $HOME/.gdbinit
# echo add-auto-load-safe-path / >> $HOME/.gdbinit

qemu-system-x86_64 \
    -enable-kvm \
    -cpu Haswell-noTSX-IBRS,vmx=on \
    -machine q35 \
    -m 8G \
    -s -S \
    -nographic \
    -kernel $BZIMAGE \
    -append 'console=ttyS0 earlyprintk=ttyS0,115200,keep' \

exit 0
