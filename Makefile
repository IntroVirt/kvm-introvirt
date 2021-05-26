include config.mk

build:
	cp $(KERNEL_CONFIG_FILE) ./kernel/.config
	cp $(KERNEL_SYMVERS_FILE) ./kernel/
	$(MAKE) -C ./kernel/ prepare
	$(MAKE) -C ./kernel/ modules_prepare
	$(MAKE) -C ./kernel/ M=arch/x86/kvm/

clean:
	$(MAKE) -C ./kernel/ M=arch/x86/kvm/ clean

distclean:
	rm -rf ./kernel/
	rm -f config.mk
	rm -f .build_vars

all: build

install: build
	mkdir -p $(INSTALL_DIR)
	cp ./kernel/arch/x86/kvm/kvm.ko $(INSTALL_DIR)
	cp ./kernel/arch/x86/kvm/kvm-intel.ko $(INSTALL_DIR)
	cp ./kernel/arch/x86/kvm/kvm-amd.ko $(INSTALL_DIR)
