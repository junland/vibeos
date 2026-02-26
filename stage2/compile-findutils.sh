compile_findutils() {
	msg "Compiling Findutils ${FINDUTILS_VERSION}..."

	extract_file "$SOURCES_DIR/findutils-${FINDUTILS_VERSION}.tar.xz" "$WORK_DIR"

	cd "$WORK_DIR"

	run_configure \
		--prefix=/usr \
		--localstatedir=/var/lib/locate \
		--host=$LFS_TGT \
		--build=$(build-aux/config.guess)

	make -j$(nproc)

	make DESTDIR="${TARGET_ROOTFS}" install

	clean_dir "$WORK_DIR"
}
