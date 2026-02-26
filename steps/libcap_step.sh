#!/bin/bash
# Libcap Step - Build and install libcap in chroot

LIBCAP_VER="2.76"

step_chroot_libcap() {
	extract_file "${SOURCES_DIR}/libcap-${LIBCAP_VER}.tar.xz" "${WORK_DIR}/libcap-${LIBCAP_VER}"

	cd "${WORK_DIR}/libcap-${LIBCAP_VER}"

	msg "Configuring libcap..."

	sed -i '/install -m.*STA/d' libcap/Makefile

	msg "Building libcap..."

	make prefix=/usr lib=lib

	msg "Checking libcap..."

	make test

	msg "Installing libcap..."

	make prefix=/usr lib=lib install

	clean_work_dir
}
