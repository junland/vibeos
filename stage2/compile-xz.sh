#
# Compile Xz
#
msg "Compiling Xz ${XZ_VERSION}..."

extract_file "$SOURCES_DIR/xz-${XZ_VERSION}.tar.xz" "$WORK_DIR"

cd "$WORK_DIR"

run_configure \
	--prefix=/usr \
	--host=$LFS_TGT \
	--build=$(build-aux/config.guess) \
	--disable-static \
	--docdir=/usr/share/doc/xz-${XZ_VERSION}

make -j$(nproc)

make DESTDIR="${TARGET_ROOTFS}" install

rm -v $TARGET_ROOTFS/usr/lib/liblzma.la

clean_dir "$WORK_DIR"
