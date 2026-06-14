#!/bin/bash
# Glibc Step - Build and install glibc

GLIBC_VER="2.42"

step_glibc() {
	extract_file "${SOURCES_DIR}/glibc-${GLIBC_VER}.tar.gz" "${WORK_DIR}/glibc-${GLIBC_VER}"

	msg "Configuring glibc..."

	cd "${WORK_DIR}/glibc-${GLIBC_VER}"

	case ${TARGET_CPU_ARCH} in
	x86_64)
		ln -sfv ../lib/ld-linux-x86-64.so.2 "${TARGET_ROOTFS_DIR}/lib64"
		ln -sfv ../lib/ld-linux-x86-64.so.2 "${TARGET_ROOTFS_DIR}/lib64/ld-lsb-x86-64.so.3"
		;;
	aarch64)
		ln -sfv ../lib/ld-linux-aarch64.so.1 "${TARGET_ROOTFS_DIR}/lib64"
		ln -sfv ../lib/ld-linux-aarch64.so.1 "${TARGET_ROOTFS_DIR}/lib64/ld-lsb-aarch64.so.3"
		;;
	riscv64)
		ln -sfv ../lib/ld-linux-riscv64-lp64d.so.1 "${TARGET_ROOTFS_DIR}/lib64"
		ln -sfv ../lib/ld-linux-riscv64-lp64d.so.1 "${TARGET_ROOTFS_DIR}/lib64/ld-lsb-riscv64.so.3"
		;;
	*)
		echo "Unknown architecture: ${TARGET_CPU_ARCH}"
		exit 1
		;;
	esac

	patch -Np1 -i "${SOURCES_DIR}/glibc-${GLIBC_VER}-fhs-1.patch"

	mkdir -vp "${WORK_DIR}/glibc-${GLIBC_VER}/build"

	cd "${WORK_DIR}/glibc-${GLIBC_VER}/build"

	echo "rootsbindir=/usr/sbin" >configparms

	../configure \
		--prefix=/usr \
		--host="${LFS_TGT}" \
		--build="$(../scripts/config.guess)" \
		--with-headers="${TARGET_ROOTFS_DIR}/usr/include" \
		--enable-kernel=5.4 \
		--disable-nscd \
		libc_cv_slibdir=/usr/lib

	msg "Building glibc..."

	make

	msg "Installing glibc..."

	make install DESTDIR="${TARGET_ROOTFS_DIR}"

	sed '/RTLDLIST=/s@/usr@@g' -i "${TARGET_ROOTFS_DIR}/usr/bin/ldd"

	msg "Verify that compiling and linking works..."

	echo 'int main(){}' | "${LFS_TGT}"-gcc -xc -

	readelf -l a.out | grep ld-linux

	rm -v a.out

	clean_dir "${WORK_DIR}"
}

step_chroot_glibc() {
	extract_file "${SOURCES_DIR}/glibc-${GLIBC_VER}.tar.gz" "${WORK_DIR}/glibc-${GLIBC_VER}"

	cd "${WORK_DIR}/glibc-${GLIBC_VER}"

	msg "Patching glibc..."

	patch -Np1 -i "${SOURCES_DIR}/glibc-${GLIBC_VER}-fhs-1.patch"

	msg "Configuring glibc..."

	mkdir -v build

	cd build

	echo "rootsbindir=/usr/sbin" >configparms

	../configure \
		--prefix=/usr \
		--disable-werror \
		--disable-nscd \
		libc_cv_slibdir=/usr/lib \
		--enable-stack-protector=strong \
		--enable-kernel=5.4

	msg "Building glibc..."

	make -j1

	msg "Checking glibc..."

	# Run all tests, continuing past failures (-k). Tests known to fail in
	# chroot/virtualbox environments are allow-listed below; any failure not
	# on the list is treated as a real error.
	TIMEOUTFACTOR=15 make -k check -j1 || true

	# Tests known to fail in chroot/virtualbox environments.
	EXPECTED_FAILURES=(
		"c++-types-check"
		"io/tst-fchownat"
		"malloc/tst-tcfree2"
		"nptl/tst-eintr1"
		"nptl/tst-mutex10"
		"nptl/tst-setuid3"
		"stdlib/tst-secure-getenv"
		"support/tst-support_descriptors"
		"io/tst-lchmod"
	)

	pattern=$(
		IFS='|'
		echo "${EXPECTED_FAILURES[*]}"
	)
	
	allowed=$(grep -cE "^FAIL: ($pattern)" tests.sum || :)
	total=$(grep -c "^FAIL" tests.sum || :)

	if [ "$allowed" -ne "$total" ]; then
		echo "Error: $((total - allowed)) unexpected test failure(s) out of $total total:"
		grep -E "^FAIL" tests.sum | grep -vE "^FAIL: ($pattern)"
		exit 1
	fi

	# Disable outdated sanity check.
	sed '/test-installation/s@$(PERL)@echo not running@' -i ../Makefile

	msg "Installing glibc..."

	make install

	#  Fix a hardcoded path to the executable loader in the ldd script
	sed '/RTLDLIST=/s@/usr@@g' -i /usr/bin/ldd

	# Add ld.so.conf
	cat >/etc/ld.so.conf <<"EOF"
# Begin /etc/ld.so.conf
/usr/local/lib
/opt/lib

# Add an include directory
include /etc/ld.so.conf.d/*.conf
# End /etc/ld.so.conf
EOF

	# Generate and install locale(s)
	msg "Generating and installing locales..."
	make localedata/install-locales

	clean_dir "${WORK_DIR}"
}
