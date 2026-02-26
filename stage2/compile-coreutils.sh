compile_coreutils() {
	msg "Compiling Coreutils ${COREUTILS_VERSION}..."

	extract_file "$SOURCES_DIR/coreutils-${COREUTILS_VERSION}.tar.xz" "$WORK_DIR"

	cd "$WORK_DIR"

	run_configure \
		--prefix=/usr \
		--host=$LFS_TGT \
		--build=$(build-aux/config.guess) \
		--enable-install-program=hostname \
		--enable-no-install-program=kill,uptime

	make -j$(nproc)

	make DESTDIR="${TARGET_ROOTFS}" install

	mv -v $TARGET_ROOTFS/usr/bin/chroot $TARGET_ROOTFS/usr/sbin

	clean_dir "$WORK_DIR"
}
