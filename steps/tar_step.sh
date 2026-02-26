#!/bin/bash
# Tar Step - Build and install tar

TAR_VER="1.35"

step_tar() {
	extract_file "${SOURCES_DIR}/tar-${TAR_VER}.tar.xz" "${WORK_DIR}/tar-${TAR_VER}"

	msg "Configuring tar..."

	cd "${WORK_DIR}/tar-${TAR_VER}"

	# Reconfigure to point to our version of automake
	autoreconf -f

	./configure \
		--prefix=/usr \
		--host="${LFS_TGT}" \
		--build="$(build-aux/config.guess)"

	msg "Building tar..."

	make

	msg "Installing tar..."

	make install DESTDIR="${TARGET_ROOTFS_PATH}"

	clean_work_dir
}

step_chroot_tar() {
	extract_file "${SOURCES_DIR}/tar-${TAR_VER}.tar.xz" "${WORK_DIR}/tar-${TAR_VER}"

	cd "${WORK_DIR}/tar-${TAR_VER}"

	msg "Configuring tar..."

	FORCE_UNSAFE_CONFIGURE=1 ./configure --prefix=/usr

	msg "Building tar..."

	make

	msg "Checking tar..."

	make check

	msg "Installing tar..."

	make install

	clean_work_dir
}
