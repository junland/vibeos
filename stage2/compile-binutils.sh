#
# Compile Binutils
#
msg "Compiling Binutils ${BINUTILS_VERSION}..."

extract_file "$SOURCES_DIR/binutils-${BINUTILS_VERSION}.tar.xz" "$WORK_DIR"

cd "$WORK_DIR"

sed '6031s/$add_dir//' -i ltmain.sh

mkdir -p build && cd build

ln -s ../configure configure

run_configure \
	--prefix=/usr \
	--build=$(../config.guess) \
	--host=$LFS_TGT \
	--disable-nls \
	--enable-shared \
	--enable-gprofng=no \
	--disable-werror \
	--enable-64-bit-bfd \
	--enable-new-dtags \
	--enable-default-hash-style=gnu

make -j$(nproc)

make DESTDIR="${TARGET_ROOTFS}" install

rm -v $TARGET_ROOTFS/usr/lib/lib{bfd,ctf,ctf-nobfd,opcodes}.la

clean_dir "$WORK_DIR"
