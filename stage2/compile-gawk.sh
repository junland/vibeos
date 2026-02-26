compile_gawk() {
	msg "Compiling Gawk ${GAWK_VERSION}..."

	extract_file "$SOURCES_DIR/gawk-${GAWK_VERSION}.tar.xz" "$WORK_DIR"

	cd "$WORK_DIR"

	sed -i 's/extras//' Makefile.in

	run_configure \
		--prefix=/usr \
		--host=$LFS_TGT \
		--build=$(build-aux/config.guess)

	make -j$(nproc)

	make DESTDIR="${TARGET_ROOTFS}" install

	clean_dir "$WORK_DIR"
}
