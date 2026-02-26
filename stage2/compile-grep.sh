compile_grep() {
	msg "Compiling Grep ${GREP_VERSION}..."

	extract_file "$SOURCES_DIR/grep-${GREP_VERSION}.tar.xz" "$WORK_DIR"

	cd "$WORK_DIR"

	run_configure \
		--prefix=/usr \
		--host=$LFS_TGT \
		--build=$(build-aux/config.guess)

	make -j$(nproc)

	make DESTDIR="${TARGET_ROOTFS}" install

	clean_dir "$WORK_DIR"
}
