#!/bin/bash
# Autoconf Step - Build and install autoconf in chroot

AUTOCONF_VER="2.72"

step_chroot_autoconf() {
	extract_file "${SOURCES_DIR}/autoconf-${AUTOCONF_VER}.tar.xz" "${WORK_DIR}/autoconf-${AUTOCONF_VER}"

	cd "${WORK_DIR}/autoconf-${AUTOCONF_VER}"

	msg "Configuring autoconf..."

	./configure --prefix=/usr

	msg "Building autoconf..."

	make

	msg "Checking autoconf..."

	make check

	msg "Installing autoconf..."

	make install

	clean_dir ${WORK_DIR}
}
