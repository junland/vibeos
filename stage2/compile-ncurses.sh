#
# Compile Ncurses
#
msg "Compiling Ncurses ${NCURSES_VERSION}..."

extract_file "$SOURCES_DIR/ncurses-${NCURSES_VERSION}.tgz" "$WORK_DIR"

cd "$WORK_DIR"

mkdir -p build

ln -s ../configure build/configure

pushd build
run_configure --prefix=$TOOLCHAIN_DIR AWK=gawk
make -C include
make -C progs tic
install progs/tic $TOOLCHAIN_DIR/bin
popd

run_configure \
	--prefix=/usr \
	--host=$LFS_TGT \
	--build=$(./config.guess) \
	--mandir=/usr/share/man \
	--with-manpage-format=normal \
	--with-shared \
	--without-normal \
	--with-cxx-shared \
	--without-debug \
 --without-ada \
	--disable-stripping \
	AWK=gawk

make -j$(nproc)

make DESTDIR="${TARGET_ROOTFS}" install

ln -sv libncursesw.so $TARGET_ROOTFS/usr/lib/libncurses.so

sed -e 's/^#if.*XOPEN.*$/#if 1/' -i $TARGET_ROOTFS/usr/include/curses.h

clean_dir "$WORK_DIR"
