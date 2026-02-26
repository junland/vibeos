compile_file() {
	msg "Compiling File ${FILE_VERSION}..."

	extract_file "$SOURCES_DIR/file-${FILE_VERSION}.tar.gz" "$WORK_DIR"

	cd "$WORK_DIR"

	mkdir build

	ln -s ../configure build/configure

	pushd build
	../configure \
		--disable-bzlib \
		--disable-libseccomp \
		--disable-xzlib \
		--disable-zlib
	make
	popd

	run_configure --prefix=/usr --host=$LFS_TGT --build=$(./config.guess)

	make FILE_COMPILE=$(pwd)/build/src/file -j$(nproc)

	make DESTDIR="${TARGET_ROOTFS}" install

	rm -v $TARGET_ROOTFS/usr/lib/libmagic.la

	clean_dir "$WORK_DIR"
}
