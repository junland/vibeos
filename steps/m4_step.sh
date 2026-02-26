#!/bin/bash
# M4 Step - Build and install m4

M4_VER="1.4.21"

step_m4() {
	extract_file "${SOURCES_DIR}/m4-${M4_VER}.tar.xz" "${WORK_DIR}/m4-${M4_VER}"

	msg "Preparing m4 build environment..."

	cd "${WORK_DIR}/m4-${M4_VER}"

	msg "Configuring m4..."

	./configure --prefix=/usr --host="${LFS_TGT}" --build="$(build-aux/config.guess)"

	msg "Building m4..."

	make

	msg "Installing m4..."

	make install DESTDIR="${TARGET_ROOTFS_PATH}"

	clean_work_dir
}

step_chroot_m4() {
	extract_file "${SOURCES_DIR}/m4-${M4_VER}.tar.xz" "${WORK_DIR}/m4-${M4_VER}"

	cd "${WORK_DIR}/m4-${M4_VER}"

	msg "Configuring m4..."

	./configure --prefix=/usr

	msg "Building m4..."

	make

	msg "Checking m4..."

	make check

	msg "Installing m4..."

	make install

	clean_work_dir
}
