#!/bin/bash

set -e
set +h

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/_common.sh"

TOOLCHAIN_DIR=$1
TARGET_CPU_ARCH=${2:-x86_64}
TARGET_ROOTFS=$3

SOURCES_DIR=${SOURCES_DIR:-$(pwd)/sources}
WORK_DIR=${WORK_DIR:-$(pwd)/work}

M4_VERSION=1.4.21
NCURSES_VERSION=6.5-20250809
BASH_VERSION=5.3
COREUTILS_VERSION=9.10
FILE_VERSION=5.46
FINDUTILS_VERSION=4.10.0
DIFFUTILS_VERSION=3.12
GAWK_VERSION=5.3.2
GREP_VERSION=3.12
GZIP_VERSION=1.14
MAKE_VERSION=4.4.1
PATCH_VERSION=2.8
SED_VERSION=4.9
TAR_VERSION=1.35
BINUTILS_VERSION=2.46.0
GMP_VERSION=6.3.0
MPFR_VERSION=4.2.2
MPC_VERSION=1.3.1
GCC_VERSION=15.2.0
XZ_VERSION=5.8.1

if [ -z "$TOOLCHAIN_DIR" ] || [ -z "$TARGET_ROOTFS" ]; then
	msg "Usage: $0 <toolchain-directory> [target-cpu-arch] <target-rootfilesystem>" >&2
	exit 1
fi

if [ ! -d "$TOOLCHAIN_DIR" ]; then
	msg "Error: Toolchain directory '$TOOLCHAIN_DIR' does not exist." >&2
	exit 1
fi

# Determine the sysroot directory based on the target CPU architecture
case "$TARGET_CPU_ARCH" in
x86-64 | x86_64 | amd64 | x64)
	TOOLCHAIN_SYSROOT_DIR="x86_64-buildroot-linux-gnu/sysroot"
	;;
arm64 | aarch64)
	TOOLCHAIN_SYSROOT_DIR="aarch64-buildroot-linux-gnu/sysroot"
	;;
*)
	msg "Unsupported target architecture: $TARGET_CPU_ARCH" >&2
	exit 1
	;;
esac

export PATH="$TOOLCHAIN_DIR/bin:$PATH"

msg "PATH set to: $PATH"

# Check if the required toolchain binaries are available
REQUIRED_BINARIES=(
	"${TARGET_CPU_ARCH}-buildroot-linux-gnu-gcc"
	"${TARGET_CPU_ARCH}-buildroot-linux-gnu-g++"
	"${TARGET_CPU_ARCH}-buildroot-linux-gnu-ar"
	"${TARGET_CPU_ARCH}-buildroot-linux-gnu-as"
	"${TARGET_CPU_ARCH}-buildroot-linux-gnu-ld"
	"${TARGET_CPU_ARCH}-buildroot-linux-gnu-ranlib"
	"${TARGET_CPU_ARCH}-buildroot-linux-gnu-strip"
)

for binary in "${REQUIRED_BINARIES[@]}"; do
	if ! command -v "$binary" &>/dev/null; then
		msg "Error: Required toolchain binary '$binary' not found in PATH." >&2
		exit 1
	fi
done

# Setup the target root filesystem for the chroot environment
if [ ! -d "$TARGET_ROOTFS" ]; then
	# Create the target root filesystem directory if it doesn't exist
	mkdir -p "$TARGET_ROOTFS"
fi

# Setup work and sources directories
if [ ! -d "$WORK_DIR" ]; then
	mkdir -p "$WORK_DIR"
fi

if [ ! -d "$SOURCES_DIR" ]; then
	mkdir -p "$SOURCES_DIR"
fi

# Copy sysroot contents to the target root filesystem
if [ -d "$TOOLCHAIN_DIR/$TOOLCHAIN_SYSROOT_DIR" ]; then
	msg "Copying sysroot from $TOOLCHAIN_DIR/$TOOLCHAIN_SYSROOT_DIR to $TARGET_ROOTFS..."
	rsync -a "$TOOLCHAIN_DIR/$TOOLCHAIN_SYSROOT_DIR/" "$TARGET_ROOTFS/"
else
	msg "Error: Sysroot directory '$TOOLCHAIN_DIR/$TOOLCHAIN_SYSROOT_DIR' does not exist." >&2
	exit 1
fi

# Define variables
export CHOST="${TARGET_CPU_ARCH}-buildroot-linux-gnu"
export LFS_TGT="${TARGET_CPU_ARCH}-buildroot-linux-gnu"
export CFLAGS="--sysroot=$TARGET_ROOTFS -I$TARGET_ROOTFS/usr/include"
export LDFLAGS="--sysroot=$TARGET_ROOTFS -L$TARGET_ROOTFS/usr/lib"
export PKG_CONFIG_PATH="$TARGET_ROOTFS/usr/lib/pkgconfig:$TARGET_ROOTFS/usr/share/pkgconfig"
export PKG_CONFIG_LIBDIR="$TARGET_ROOTFS/usr/lib/pkgconfig:$TARGET_ROOTFS/usr/share/pkgconfig"

#
# Start building components in the for the chroot environment
#

# Compile Binutils
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

# Compile M4
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

# Compile Ncurses
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

# Compile Bash
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

# Compile Coreutils
msg "Compiling Coreutils ${COREUTILS_VERSION}..."

extract_file "$SOURCES_DIR/coreutils-${COREUTILS_VERSION}.tar.xz" "$WORK_DIR"

cd "$WORK_DIR"

run_configure \
	--prefix=/usr \
	--host=$LFS_TGT \
	--build=$(build-aux/config.guess) \
	--enable-install-program=hostname \
	--enable-no-install-program=kill,uptime

make -j$(nproc)

make DESTDIR="${TARGET_ROOTFS}" install

mv -v $TARGET_ROOTFS/usr/bin/chroot $TARGET_ROOTFS/usr/sbin

clean_dir "$WORK_DIR"

# Compile Diffutils
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

# Compile File
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

# Compile Findutils
msg "Compiling Findutils ${FINDUTILS_VERSION}..."

extract_file "$SOURCES_DIR/findutils-${FINDUTILS_VERSION}.tar.xz" "$WORK_DIR"

cd "$WORK_DIR"

run_configure \
	--prefix=/usr \
	--localstatedir=/var/lib/locate \
	--host=$LFS_TGT \
	--build=$(build-aux/config.guess)

make -j$(nproc)

make DESTDIR="${TARGET_ROOTFS}" install

clean_dir "$WORK_DIR"

# Compile Gawk
msg "Compiling Gawk ${GAWK_VERSION}..."

extract_file "$SOURCES_DIR/gawk-${GAWK_VERSION}.tar.xz" "$WORK_DIR"

cd "$WORK_DIR"

sed -i 's/extras//' Makefile.in

run_configure \
	--prefix=/usr \
	--host=$LFS_TGT \
	--build=$(build-aux/config.guess)

make -j$(nproc)

make DESTDIR="${TARGET_ROOTFS}" install

clean_dir "$WORK_DIR"

# Compile Grep
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

# Compile Gzip
msg "Compiling Gzip ${GZIP_VERSION}..."

extract_file "$SOURCES_DIR/gzip-${GZIP_VERSION}.tar.xz" "$WORK_DIR"

cd "$WORK_DIR"

run_configure --prefix=/usr --host=$LFS_TGT

make -j$(nproc)

make DESTDIR="${TARGET_ROOTFS}" install

clean_dir "$WORK_DIR"

# Compile Make
msg "Compiling Make ${MAKE_VERSION}..."

extract_file "$SOURCES_DIR/make-${MAKE_VERSION}.tar.gz" "$WORK_DIR"

cd "$WORK_DIR"

run_configure \
	--prefix=/usr \
	--host=$LFS_TGT \
	--build=$(build-aux/config.guess)

make -j$(nproc)

make DESTDIR="${TARGET_ROOTFS}" install

clean_dir "$WORK_DIR"

# Compile Patch
msg "Compiling Patch ${PATCH_VERSION}..."

extract_file "$SOURCES_DIR/patch-${PATCH_VERSION}.tar.xz" "$WORK_DIR"

cd "$WORK_DIR"

run_configure \
	--prefix=/usr \
	--host=$LFS_TGT \
	--build=$(build-aux/config.guess)

make -j$(nproc)

make DESTDIR="${TARGET_ROOTFS}" install

clean_dir "$WORK_DIR"

# Compile Sed
msg "Compiling Sed ${SED_VERSION}..."

extract_file "$SOURCES_DIR/sed-${SED_VERSION}.tar.xz" "$WORK_DIR"

cd "$WORK_DIR"

run_configure \
	--prefix=/usr \
	--host=$LFS_TGT \
	--build=$(build-aux/config.guess)

make -j$(nproc)

make DESTDIR="${TARGET_ROOTFS}" install

clean_dir "$WORK_DIR"

# Compile Tar
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

# Compile Xz
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

# Compile GCC
msg "Compiling GCC ${GCC_VERSION}..."

extract_file "$SOURCES_DIR/gcc-${GCC_VERSION}.tar.xz" "$WORK_DIR"
extract_file "$SOURCES_DIR/gmp-${GMP_VERSION}.tar.xz" "$WORK_DIR/gmp"
extract_file "$SOURCES_DIR/mpfr-${MPFR_VERSION}.tar.xz" "$WORK_DIR/mpfr"
extract_file "$SOURCES_DIR/mpc-${MPC_VERSION}.tar.gz" "$WORK_DIR/mpc"

cd "$WORK_DIR"

mkdir -p build && cd build

# Link configure script from parent.
ln -s ../configure configure

run_configure \
	--build=$(../config.guess) \
	--host=$LFS_TGT \
	--target=$LFS_TGT \
	--prefix=/usr \
	--with-build-sysroot=$TARGET_ROOTFS \
	--enable-default-pie \
	--enable-default-ssp \
	--disable-nls \
	--disable-multilib \
	--disable-libatomic \
	--disable-libgomp \
	--disable-libquadmath \
	--disable-libsanitizer \
	--disable-libssp \
	--disable-libvtv \
	--enable-languages=c,c++ \
	LDFLAGS_FOR_TARGET=-L$PWD/$LFS_TGT/libgcc

make -j$(nproc)

make DESTDIR="${TARGET_ROOTFS}" install

clean_dir "$WORK_DIR"
