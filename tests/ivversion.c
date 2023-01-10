// SPDX-License-Identifier: GPL-2.0-only
/*
 * iv_version
 *
 * Copyright (C) 2022, Assured Information Security, Inc.
 *
 * Test kvm-introvirt
 */

#define _GNU_SOURCE /* for program_invocation_short_name */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/resource.h>

#include <test_util.h>

#include "kvm_util.h"

int main(int argc, char *argv[])
{
	int kvm_fd = open("/dev/kvm", O_RDWR);
	int version = ioctl(kvm_fd, KVM_GET_API_VERSION, 0);
	printf("KVM version: %d\n", version);

	int iv_version = kvm_check_cap(KVM_CAP_INTROSPECTION);
	printf("IV version: %d\n", iv_version);

	return 0;
}
