#!/bin/bash
# Gawk Step - Build and install gawk

GAWK_VER="5.3.2"

step_gawk() {
	extract_file "${SOURCES_DIR}/gawk-${GAWK_VER}.tar.xz" "${WORK_DIR}/gawk-${GAWK_VER}"

	msg "Configuring gawk..."

	cd "${WORK_DIR}/gawk-${GAWK_VER}"

	# Reconfigure to point to our version of automake
	autoreconf -f

	sed -i 's/extras//' Makefile.in

	./configure \
		--prefix=/usr \
		--host="${LFS_TGT}" \
		--build="$(build-aux/config.guess)"

	msg "Building gawk..."

	make

	msg "Installing gawk..."

	make install DESTDIR="${TARGET_ROOTFS_PATH}"

	clean_work_dir
}

step_chroot_gawk() {
	extract_file "${SOURCES_DIR}/gawk-${GAWK_VER}.tar.xz" "${WORK_DIR}/gawk-${GAWK_VER}"

	cd "${WORK_DIR}/gawk-${GAWK_VER}"

	msg "Configuring gawk..."

	sed -i 's/extras//' Makefile.in

	./configure --prefix=/usr

	msg "Building gawk..."

	make

	# msg "Checking gawk..."

	# chown -R tester .

	# su tester -c "PATH=$PATH make check"

	msg "Installing gawk..."

	rm -f /usr/bin/gawk-${GAWK_VER}

	make install

	clean_work_dir
}
