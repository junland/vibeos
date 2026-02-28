#!/bin/bash
# Linux Headers Step - Install kernel headers

LINUX_VER="6.16.1"

step_linux_headers() {
	extract_file "${SOURCES_DIR}/linux-${LINUX_VER}.tar.xz" "${WORK_DIR}/linux-${LINUX_VER}"

	msg "Confirming files..."

	cd "${WORK_DIR}/linux-${LINUX_VER}"

	make mrproper

	msg "Building headers..."

	make headers

	msg "Installing headers..."

	find usr/include -type f ! -name '*.h' -delete

	mkdir -vp "${TARGET_ROOTFS_DIR}/usr"

	cp -rv usr/include "${TARGET_ROOTFS_DIR}/usr"

	clean_dir ${WORK_DIR}
}
