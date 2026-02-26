#!/bin/bash
# Make Step - Build and install make

MAKE_VER="4.4.1"

step_make() {
	extract_file "${SOURCES_DIR}/make-${MAKE_VER}.tar.gz" "${WORK_DIR}/make-${MAKE_VER}"

	msg "Configuring make..."

	cd "${WORK_DIR}/make-${MAKE_VER}"

	# Reconfigure to point to our version of automake
	autoreconf -f

	./configure \
		--build="$(build-aux/config.guess)" \
		--prefix=/usr \
		--without-guile \
		--host="${LFS_TGT}"

	msg "Building make..."

	make

	msg "Installing make..."

	make install DESTDIR="${TARGET_ROOTFS_DIR}"

	clean_work_dir
}

step_chroot_make() {
	extract_file "${SOURCES_DIR}/make-${MAKE_VER}.tar.gz" "${WORK_DIR}/make-${MAKE_VER}"

	cd "${WORK_DIR}/make-${MAKE_VER}"

	msg "Configuring make..."

	./configure --prefix=/usr

	msg "Building make..."

	make

	msg "Checking make..."

	chown -R tester .

	su tester -c "PATH=$PATH make check"

	msg "Installing make..."

	make install

	clean_work_dir
}
