#!/bin/bash
# Findutils Step - Build and install findutils

FINDUTILS_VER="4.10.0"

step_findutils() {
	extract_file "${SOURCES_DIR}/findutils-${FINDUTILS_VER}.tar.xz" "${WORK_DIR}/findutils-${FINDUTILS_VER}"

	msg "Configuring findutils..."

	cd "${WORK_DIR}/findutils-${FINDUTILS_VER}"

	# Reconfigure to point to our version of automake
	autoreconf -f

	./configure \
		--prefix=/usr \
		--localstatedir=/var/lib/locate \
		--host="${LFS_TGT}" \
		--build="$(build-aux/config.guess)"

	msg "Building findutils..."

	make

	msg "Installing findutils..."

	make install DESTDIR="${TARGET_ROOTFS_DIR}"

	clean_dir ${WORK_DIR}
}

step_chroot_findutils() {
	extract_file "${SOURCES_DIR}/findutils-${FINDUTILS_VER}.tar.xz" "${WORK_DIR}/findutils-${FINDUTILS_VER}"

	cd "${WORK_DIR}/findutils-${FINDUTILS_VER}"

	msg "Configuring findutils..."

	./configure \
		--prefix=/usr \
		--localstatedir=/var/lib/locate

	msg "Building findutils..."

	make

	msg "Checking findutils..."

	chown -R tester .

	su tester -c "PATH=$PATH make check"

	msg "Installing findutils..."

	make install

	clean_dir ${WORK_DIR}
}
