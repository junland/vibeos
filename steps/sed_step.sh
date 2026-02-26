#!/bin/bash
# Sed Step - Build and install sed

SED_VER="4.9"

step_sed() {
	extract_file "${SOURCES_DIR}/sed-${SED_VER}.tar.xz" "${WORK_DIR}/sed-${SED_VER}"

	msg "Configuring sed..."

	cd "${WORK_DIR}/sed-${SED_VER}"

	# Reconfigure to point to our version of automake
	autoreconf -f

	./configure \
		--prefix=/usr \
		--host="${LFS_TGT}" \
		--build="$(build-aux/config.guess)"

	msg "Building sed..."

	make

	msg "Installing sed..."

	make install DESTDIR="${TARGET_ROOTFS_DIR}"

	clean_work_dir
}

step_chroot_sed() {
	extract_file "${SOURCES_DIR}/sed-${SED_VER}.tar.xz" "${WORK_DIR}/sed-${SED_VER}"

	cd "${WORK_DIR}/sed-${SED_VER}"

	msg "Configuring sed..."

	./configure --prefix=/usr

	msg "Building sed..."

	make

	msg "Checking sed..."

	chown -R tester .

	su tester -c "PATH=$PATH make -k check"

	msg "Installing sed..."

	make install

	clean_work_dir
}
