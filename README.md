# kvm-introvirt

IntroVirt KVM module. Intel CPUs have full support. AMD CPUs are lacking support for breakpoints but syscall tracing should work.

## Installation Instructions

kvm-introvirt can installed from prebuilt debian packages for Ubuntu 18.04, 22.04, or 24.04. The latest deb packages can be downloaded from the releases.

1. Make sure SecureBoot is disabled on your system (you can also run IntroVirt nested in KVM)
    * _If someone wants to help me figure out a way around this please do!_
1. Download the latest `.deb` package for your OS and kernel version
1. Shut down any running VMs
1. Change to the download directory
1. Run: `sudo apt install ./kvm-introvirt-<version>.deb`

If you cannot find a deb package that matches your OS or kernel version, see below how to build and patch yourself. Feel free to submit a PR for a working patch for a new OS/kernel.

## Build Instructions

1. Edit `/etc/apt/sources.list` to enable the primary `deb-src` repos for your distribution (More info here: https://wiki.ubuntu.com/Kernel/BuildYourOwnKernel)
1. Run `sudo apt update` after editing your `sources.list`
1. Install the dependencies:

    ```shell
    sudo apt-get install -y \
        bc devscripts quilt git flex bison libssl-dev libelf-dev debhelper \
        libncurses-dev gawk openssl dkms libudev-dev libpci-dev libiberty-dev \
        autoconf llvm \
        linux-headers-$(uname -r) \
        linux-modules-$(uname -r)

    # Need to make sure deb-src repos are enabled
    sudo apt build-dep linux linux-image-unsigned-$(uname -r)
    ```

1. Clone and build the module (assuming the folder exists for your kernel)
    * You can install an older supported kernel through `apt`, and boot into it if needed.

    ```shell
    git clone https://github.com/IntroVirt/kvm-introvirt.git
    cd ./kvm-introvirt

    # If configure says the kernel is unsupported, see the next section on "Supporting a new kernel version"
    ./configure

    make -j
    sudo make install
    ```

    _NOTE: The patched version of `kvm.ko`, `kvm-intel.ko`, and `kvm-amd.ko` are installed to `/lib/modules/$(uname -r)/updates/introvirt/`_

1. Reload the KVM module

    ```shell
    sudo rmmod kvm-intel kvm
    sudo modprobe kvm-intel
    ```

If there are issues/errors loading the modified version of KVM, check `dmesg` for more details. To undo these changes and get the original version of KVM back:

```shell
# Manually
sudo rmmod kvm-intel kvm
sudo rm -rf /lib/modules/$(uname -r)/updates/introvirt/
sudo depmod -a $(uname -r)
sudo modprobe kvm-intel

# Or automatically
make uninstall
```

## Supporting a new kernel version

To support a new version, reset the environment and create a new branch.

```shell
# Cleans up the kernel folder
make distclean

# Make a branch to support the new kernel
git checkout -b ubuntu/$(lsb_release -sc)/Ubuntu-hwe-$(uname -r)

# Make the directory for the patch
mkdir -p ubuntu/$(lsb_release -sc)/hwe/$(uname -r)

# Copy the most recent patch directory from a prior kernel
# Whichever kernel is closest to the one you're patching
cp -r ubuntu/<codename>/hwe/<kernel>/patches ubuntu/$(lsb_release -sc)/hwe/$(uname -r)/

# Set your email/name to be used in the changelog which is updated by ./configure
# if those variables are set
export DEBEMAIL="<your_email>"
export DEBFULLNAME="<your name>"

# Run configure to pull the kernel source into ./kernel and attempt to apply the old patch
./configure
```

When running `./configure`, quilt will attempt to apply the patch to the new target kernel. If the patch does not cleanly apply, you will need to update it. When the patch fails to apply, we need to force apply what we can:

```shell
cd ubuntu/$(lsb_release -sc)/hwe/$(uname -r)
quilt push -a -f
```

This will apply the parts of the patch that didn't fail, and create `*.rej` files for the parts that failed. Now, manually inspect the `*.rej` files and adapt them into the source to include the changes required for the patch to work. This is a manual process that requires testing/validation that the changes work as intended. Depending on how much the kernel changed, it could be a simple fix, or a more complicated process.

Once done, or if the patch applied successfully in the first place:

```shell
# Update the .patch file with the changes (if any) to the patch
quilt refresh
# Rename the patch for this kernel.
quilt rename kvm-introvirt-hwe-$(uname -r)

# Generate the header text for the quilt patch
cat << EOF
Description: KVM IntroVirt patch for Ubuntu HWE kernel $(uname -r)
 The KVM IntroVirt patch adds introspection support to KVM. This allows
 for inspection of virtual machine memory and manipulation of running processes in-guest.
 This patch is required for compatibility with the user-land IntroVirt library.
Author: AIS Inc., introvirt@ainfosec.com
Origin: upstream, https://github.com/IntroVirt/kvm-introvirt
Bug: https://github.com/IntroVirt/kvm-introvirt/issues
Last-Update: $(date +"%Y-%m-%d")
---
This patch header follows DEP-3: http://dep.debian.net/deps/dep3/
EOF

# Copy paste the output from the previous command as the new header for the patch
quilt header -e

# Change back to the repo root
cd ../../../../

# Run configure again and the patch should apply cleanly
./configure
# Build it
make -j
# Build the .deb package
make package
# Install
sudo dpkg -i ./dist/kvm-introvirt-$(uname -r)*.deb

# Un-apply the patch
cd ubuntu/$(lsb_release -sc)/hwe/$(uname -r)
quilt pop
cd -

# Check dmesg to confirm success
sudo dmesg
# Should see 2 lines like the following:
# kvm: loading out-of-tree module taints kernel.
# kvm: module verification failed: signature and/or required key missing - tainting kernel
```

Use `dmesg` for more information if `modprobe` fails.

### Finalize new version support

1. Add and commit changes, then push up the new branch (on a fork) and submit a PR
