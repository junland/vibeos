compile_gzip() {
	msg "Compiling Gzip ${GZIP_VERSION}..."

	extract_file "$SOURCES_DIR/gzip-${GZIP_VERSION}.tar.xz" "$WORK_DIR"

	cd "$WORK_DIR"

	run_configure --prefix=/usr --host=$LFS_TGT

	make -j$(nproc)

	make DESTDIR="${TARGET_ROOTFS}" install

	clean_dir "$WORK_DIR"
}
