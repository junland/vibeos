#!/bin/bash
# Bash Step - Build and install bash

BASH_VER="5.3"

step_bash() {
	extract_file "${SOURCES_DIR}/bash-${BASH_VER}.tar.gz" "${WORK_DIR}/bash-${BASH_VER}"

	msg "Configuring bash..."

	cd "${WORK_DIR}/bash-${BASH_VER}"

	./configure \
		--prefix=/usr \
		--build="$(sh support/config.guess)" \
		--host="${LFS_TGT}" \
		--without-bash-malloc

	msg "Building bash..."

	make

	msg "Installing bash..."

	make install DESTDIR="${TARGET_ROOTFS_DIR}"

	ln -svf bash "${TARGET_ROOTFS_DIR}"/usr/bin/sh

	clean_dir ${WORK_DIR}
}

step_chroot_bash() {
	extract_file "${SOURCES_DIR}/bash-$BASH_VER.tar.gz" "${WORK_DIR}/bash-$BASH_VER"

	cd "${WORK_DIR}/bash-$BASH_VER"

	msg "Configuring bash..."

	./configure \
		--prefix=/usr \
		--without-bash-malloc \
		--with-installed-readline \
		--docdir=/usr/share/doc/bash-${BASH_VER}

	msg "Building bash..."

	make

	msg "Checking bash..."

	chown -R tester .

	msg "Installing bash..."

	make install

	clean_dir ${WORK_DIR}
}