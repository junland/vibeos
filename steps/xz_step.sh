#!/bin/bash
# Xz Step - Build and install xz

XZ_VER="5.8.1"

step_xz() {
	extract_file "${SOURCES_DIR}/xz-${XZ_VER}.tar.xz" "${WORK_DIR}/xz-${XZ_VER}"

	msg "Configuring xz..."

	cd "${WORK_DIR}/xz-${XZ_VER}"

	# Reconfigure to point to our version of automake
	autoreconf -f

	./configure \
		--prefix=/usr \
		--host="${LFS_TGT}" \
		--build="$(build-aux/config.guess)" \
		--disable-static \
		--docdir=/usr/share/doc/xz-${XZ_VER}

	msg "Building xz..."

	make

	msg "Installing xz..."

	make install DESTDIR="${TARGET_ROOTFS_DIR}"

	rm -v "${TARGET_ROOTFS_DIR}"/usr/lib/liblzma.la

	clean_work_dir
}

step_chroot_xz() {
	extract_file "${SOURCES_DIR}/xz-${XZ_VER}.tar.xz" "${WORK_DIR}/xz-${XZ_VER}"

	cd "${WORK_DIR}/xz-${XZ_VER}"

	msg "Configuring xz..."

	./configure --prefix=/usr \
		--disable-static \
		--docdir=/usr/share/doc/xz-${XZ_VER}

	msg "Building xz..."

	make

	msg "Checking xz..."

	make check

	msg "Installing xz..."

	make install

	clean_work_dir
}
