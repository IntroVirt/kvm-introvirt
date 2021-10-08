# kvm-introvirt
IntroVirt KVM module

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
