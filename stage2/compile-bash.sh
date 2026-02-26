compile_bash() {
	msg "Compiling Bash ${BASH_VERSION}..."

	extract_file "$SOURCES_DIR/bash-${BASH_VERSION}.tar.gz" "$WORK_DIR"

	cd "$WORK_DIR"

	run_configure \
		--host=$LFS_TGT \
		--prefix=/usr \
		--build=$(sh support/config.guess) \
		--without-bash-malloc

	make -j$(nproc)

	make DESTDIR="${TARGET_ROOTFS}" install

	ln -sv bash "${TARGET_ROOTFS}/usr/bin/sh"

	clean_dir "$WORK_DIR"
}
