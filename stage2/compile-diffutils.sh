compile_diffutils() {
	msg "Compiling Diffutils ${DIFFUTILS_VERSION}..."

	extract_file "$SOURCES_DIR/diffutils-${DIFFUTILS_VERSION}.tar.xz" "$WORK_DIR"

	cd "$WORK_DIR"

	run_configure \
		--prefix=/usr \
		--host=$LFS_TGT \
		gl_cv_func_strcasecmp_works=y \
		--build=$(./build-aux/config.guess)

	make -j$(nproc)

	make DESTDIR="${TARGET_ROOTFS}" install

	clean_dir "$WORK_DIR"
}
