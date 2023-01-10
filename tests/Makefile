include ../kernel/scripts/Kbuild.include
include ../config.mk

all:

top_srcdir = ../kernel
KSFT_KHDR_INSTALL := 1
UNAME_M := $(shell uname -m)
selftests_dir = ../kernel/tools/testing/selftests/kvm

LIBKVM = \
	$(selftests_dir)/lib/assert.c \
	$(selftests_dir)/lib/elf.c \
	$(selftests_dir)/lib/io.c \
	$(selftests_dir)/lib/kvm_util.c \
	$(selftests_dir)/lib/sparsebit.c
LIBKVM_x86_64 = \
	$(selftests_dir)/lib/x86_64/processor.c \
	$(selftests_dir)/lib/x86_64/vmx.c \
	$(selftests_dir)/lib/x86_64/ucall.c

TEST_GEN_PROGS_x86_64 += ivversion

TEST_GEN_PROGS += $(TEST_GEN_PROGS_$(UNAME_M))
LIBKVM += $(LIBKVM_$(UNAME_M))

INSTALL_HDR_PATH = $(top_srcdir)/usr
LINUX_HDR_PATH = $(INSTALL_HDR_PATH)/include/
LINUX_TOOL_INCLUDE = $(top_srcdir)/tools/include
CFLAGS += -Wall -Wstrict-prototypes -Wuninitialized -O2 -g -std=gnu99 \
	-fno-stack-protector -fno-PIE -I$(LINUX_TOOL_INCLUDE) \
	-I$(LINUX_HDR_PATH) -I$(selftests_dir)/include -I$(<D) \
	-I$(selftests_dir)/include/$(UNAME_M) -I$(selftests_dir)/..

no-pie-option := $(call try-run, echo 'int main() { return 0; }' | \
        $(CC) -Werror -no-pie -x c - -o "$$TMP", -no-pie)

LDFLAGS += -pthread $(no-pie-option) $(pgste-option)

# After inclusion, $(OUTPUT) is defined and
# $(TEST_GEN_PROGS) starts with $(OUTPUT)/
include $(selftests_dir)/../lib.mk

STATIC_LIBS := $(OUTPUT)/libkvm.a
LIBKVM_OBJ := $(patsubst %.c, $(OUTPUT)/%.o, $(LIBKVM))
EXTRA_CLEAN += $(LIBKVM_OBJ) $(STATIC_LIBS) cscope.*

x := $(shell mkdir -p $(sort $(dir $(LIBKVM_OBJ))))
$(LIBKVM_OBJ): $(OUTPUT)/%.o: %.c
	$(CC) $(CFLAGS) $(CPPFLAGS) $(TARGET_ARCH) -c $< -o $@

$(OUTPUT)/libkvm.a: $(LIBKVM_OBJ)
	$(AR) crs $@ $^

all: $(STATIC_LIBS) out
$(TEST_GEN_PROGS): $(STATIC_LIBS)

out: $(TEST_GEN_PROGS)
	mkdir -p ../out/tests
	cp -a $(TEST_GEN_PROGS) ../out/tests

kvm-selftests:
#	Using shell to workaround an issue when invoking make directly
	echo $(shell $(MAKE) -C $(selftests_dir))

clean-kvm-selftests:
	echo $(shell $(MAKE) -C $(selftests_dir) clean)

clean: clean-kvm-selftests
