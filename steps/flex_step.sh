#!/bin/bash
# Flex Step - Build and install flex in chroot

FLEX_VER="2.6.4"

step_chroot_flex() {
	extract_file "${SOURCES_DIR}/flex-${FLEX_VER}.tar.gz" "${WORK_DIR}/flex-${FLEX_VER}"

	cd "${WORK_DIR}/flex-${FLEX_VER}"

	msg "Configuring flex..."

	./configure \
		--prefix=/usr \
		--docdir=/usr/share/doc/flex-${FLEX_VER} \
		--disable-static

	msg "Building flex..."

	make

	msg "Checking flex..."

	make check

	msg "Installing flex..."

	make install

	ln -sv flex /usr/bin/lex

	clean_work_dir
}
