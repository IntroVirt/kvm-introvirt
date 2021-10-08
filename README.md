# kvm-introvirt
IntroVirt KVM module

# Installation Instructions

kvm-introvirt can be installed from prebuilt packages using the PPA for Ubuntu bionic and focal.
Shut down any running VMs first, and then run:
```
sudo add-apt-repository ppa:srpape/introvirt
sudo apt-get update
sudo apt-get install kvm-introvirt
```

You will have to boot into the kernel that the kvm-introvirt module is built for, if the latest package does not match what your system is running.

# Build Instructions

Install dependencies:
```
sudo apt-get install bc devscripts quilt git flex bison libssl-dev libelf-dev debhelper
```

Install the headers and modules for your target kernel
```
sudo apt-get install linux-headers-<version> linux-modules-<version>
```

Clone and build the module
```
git clone https://github.com/IntroVirt/kvm-introvirt.git
git checkout ubuntu/focal/<version>
./configure
make
sudo make install
```

Reload the KVM module
```
sudo rmmod kvm-intel kvm
sudo modprobe kvm-intel
```

# Supporting a new version

The kernel module is built based on the branch name. To support a new version, reset the environment and create a new branch:
```
make distclean
git reset --hard
git clean -x -d -f
git checkout -b ubuntu/focal/<version>
```
