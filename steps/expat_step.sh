#!/bin/bash
# Expat Step - Build and install expat in chroot

EXPAT_VER="2.7.1"

step_chroot_expat() {
	extract_file "${SOURCES_DIR}/expat-${EXPAT_VER}.tar.xz" "${WORK_DIR}/expat-${EXPAT_VER}"

	cd "${WORK_DIR}/expat-${EXPAT_VER}"

	msg "Configuring expat..."

	./configure \
		--prefix=/usr \
		--disable-static \
		--docdir=/usr/share/doc/expat-${EXPAT_VER}

	msg "Building expat..."

	make

	msg "Checking expat..."

	make check

	msg "Installing expat..."

	make install

	clean_dir ${WORK_DIR}
}
