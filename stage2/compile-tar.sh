#
# Compile Tar
#
msg "Compiling Tar ${TAR_VERSION}..."

extract_file "$SOURCES_DIR/tar-${TAR_VERSION}.tar.xz" "$WORK_DIR"

cd "$WORK_DIR"

run_configure \
	--prefix=/usr \
	--host=$LFS_TGT \
	--build=$(build-aux/config.guess)

make -j$(nproc)

make DESTDIR="${TARGET_ROOTFS}" install

clean_dir "$WORK_DIR"
