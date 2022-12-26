Source: kvm-introvirt
Section: devel
Priority: optional
Maintainer: Christopher Pelloux <git@chp.io>
Build-Depends: linux-modules-@KERNEL_VERSION_KERNEL_FLAVOR@,
               linux-headers-@KERNEL_VERSION_KERNEL_FLAVOR@,
               bc,
               devscripts,
               quilt,
               git,
               flex,
               bison,
               libssl-dev,
               libelf-dev,
               debhelper
Standards-Version: 4.4.0
Homepage: https://github.com/IntroVirt/kvm-introvirt/
Vcs-Browser: https://github.com/IntroVirt/kvm-introvirt/
Vcs-Git: https://github.com/IntroVirt/kvm-introvirt.git

Package: kvm-introvirt-@KERNEL_VERSION_KERNEL_FLAVOR@
Section: libs
Architecture: any
Pre-Depends: ${misc:Pre-Depends}
Depends: ${misc:Depends},
         linux-image-@KERNEL_VERSION_KERNEL_FLAVOR@
Multi-Arch: same
Description: virtual machine introspection library
 Virtual machine introspection KVM driver

Package: kvm-introvirt
Section: libs
Architecture: any
Pre-Depends: ${misc:Pre-Depends}
Depends: ${misc:Depends},
         kvm-introvirt-@KERNEL_VERSION_KERNEL_FLAVOR@ (=${source:Version})
Multi-Arch: same
Description: virtual machine introspection library
 Virtual machine introspection KVM driver

