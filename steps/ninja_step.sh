#!/bin/bash
# Ninja Step - Build and install ninja in chroot

NINJA_VER="1.13.1"

step_chroot_ninja() {
	extract_file "${SOURCES_DIR}/ninja-${NINJA_VER}.tar.gz" "${WORK_DIR}/ninja-${NINJA_VER}"

	cd "${WORK_DIR}/ninja-${NINJA_VER}"

	msg "Building ninja..."

	python3 configure.py --bootstrap --verbose

	msg "Installing ninja..."

	install -vm755 ninja /usr/bin/

	clean_dir ${WORK_DIR}
}
