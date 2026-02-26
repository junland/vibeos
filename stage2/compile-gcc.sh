compile_gcc() {
	msg "Compiling GCC ${GCC_VERSION}..."

	extract_file "$SOURCES_DIR/gcc-${GCC_VERSION}.tar.xz" "$WORK_DIR"
	extract_file "$SOURCES_DIR/gmp-${GMP_VERSION}.tar.xz" "$WORK_DIR/gmp"
	extract_file "$SOURCES_DIR/mpfr-${MPFR_VERSION}.tar.xz" "$WORK_DIR/mpfr"
	extract_file "$SOURCES_DIR/mpc-${MPC_VERSION}.tar.gz" "$WORK_DIR/mpc"

	cd "$WORK_DIR"

	mkdir -p build && cd build

	# Link configure script from parent.
	ln -s ../configure configure

	run_configure \
		--build=$(../config.guess) \
		--host=$LFS_TGT \
		--target=$LFS_TGT \
		--prefix=/usr \
		--with-build-sysroot=$TARGET_ROOTFS \
		--enable-default-pie \
		--enable-default-ssp \
		--disable-nls \
		--disable-multilib \
		--disable-libatomic \
		--disable-libgomp \
		--disable-libquadmath \
		--disable-libsanitizer \
		--disable-libssp \
		--disable-libvtv \
		--enable-languages=c,c++ \
		LDFLAGS_FOR_TARGET=-L$PWD/$LFS_TGT/libgcc

	make -j$(nproc)

	make DESTDIR="${TARGET_ROOTFS}" install

	clean_dir "$WORK_DIR"
}
