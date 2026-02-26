#
# Compile M4
#
msg "Compiling M4 ${M4_VERSION}..."

extract_file "$SOURCES_DIR/m4-${M4_VERSION}.tar.xz" "$WORK_DIR"

cd "$WORK_DIR"

run_configure \
	--host=$LFS_TGT \
	--prefix=/usr \
	--build=$(build-aux/config.guess)

make -j$(nproc)

make DESTDIR="${TARGET_ROOTFS}" install

clean_dir "$WORK_DIR"
