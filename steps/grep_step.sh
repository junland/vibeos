#!/bin/bash
# Grep Step - Build and install grep

GREP_VER="3.12"

step_grep() {
	extract_file "${SOURCES_DIR}/grep-${GREP_VER}.tar.xz" "${WORK_DIR}/grep-${GREP_VER}"

	msg "Configuring grep..."

	cd "${WORK_DIR}/grep-${GREP_VER}"

	# Reconfigure to point to our version of automake
	autoreconf -f

	./configure \
		--prefix=/usr \
		--host="${LFS_TGT}" \
		--build="$(build-aux/config.guess)"

	msg "Building grep..."

	make

	msg "Installing grep..."

	make install DESTDIR="${TARGET_ROOTFS_DIR}"

	clean_dir ${WORK_DIR}
}
