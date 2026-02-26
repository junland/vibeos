#!/bin/bash
# File Step - Build and install file command

FILE_VER="5.46"

step_file() {
	extract_file "${SOURCES_DIR}/file-${FILE_VER}.tar.gz" "${WORK_DIR}/file-${FILE_VER}"

	msg "Configuring temp file command..."

	cd "${WORK_DIR}/file-${FILE_VER}"

	# Reconfigure to point to our version of automake
	autoreconf -f

	mkdir build

	pushd build

	../configure \
		--disable-bzlib \
		--disable-libseccomp \
		--disable-xzlib \
		--disable-zlib

	msg "Building temp file command..."

	make

	popd

	msg "Configuring file..."

	./configure --prefix=/usr --host="${LFS_TGT}" --build="$(./config.guess)"

	msg "Building file..."

	make FILE_COMPILE="$(pwd)/build/src/file"

	msg "Installing file..."

	make install DESTDIR="${TARGET_ROOTFS_PATH}"

	rm -v "${TARGET_ROOTFS_PATH}"/usr/lib/libmagic.la

	clean_work_dir
}

step_chroot_file() {
	extract_file "${SOURCES_DIR}/file-${FILE_VER}.tar.gz" "${WORK_DIR}/file-${FILE_VER}"

	cd "${WORK_DIR}/file-${FILE_VER}"

	msg "Configuring file..."

	./configure --prefix=/usr

	msg "Building file..."

	make

	msg "Checking file..."

	make check

	msg "Installing file..."

	make install

	clean_work_dir
}