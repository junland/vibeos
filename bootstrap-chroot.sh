#!/bin/bash

set -e
set +h

TOOLCHAIN_DIR=$1
TARGET_CPU_ARCH=${2:-x86_64}
TARGET_ROOTFS=$3

SOURCES_DIR=${SOURCES_DIR:-$(pwd)/sources}

M4_VERSION=1.4.21
NCURSES_VERSION=6.6
BASH_VERSION=5.3
COREUTILS_VERSION=9.10
FILE_VERSION=5.46
FINDUTILS_VERSION=4.10.0
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

if [ -z "$TOOLCHAIN_DIR" ] || [ -z "$TARGET_ROOTFS" ]; then
	echo "Usage: $0 <toolchain-directory> [target-cpu-arch] <target-rootfilesystem>" >&2
	exit 1
fi

if [ ! -d "$TOOLCHAIN_DIR" ]; then
	echo "Error: Toolchain directory '$TOOLCHAIN_DIR' does not exist." >&2
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
	echo "Unsupported target architecture: $TARGET_CPU_ARCH" >&2
	exit 1
	;;
esac

export PATH="$TOOLCHAIN_DIR/bin:$PATH"

echo "PATH set to: $PATH"

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
		echo "Error: Required toolchain binary '$binary' not found in PATH." >&2
		exit 1
	fi
done

# Setup the target root filesystem for the chroot environment
if [ ! -d "$TARGET_ROOTFS" ]; then
	# Create the target root filesystem directory if it doesn't exist
	mkdir -p "$TARGET_ROOTFS"
fi

# Copy sysroot contents to the target root filesystem
if [ -d "$TOOLCHAIN_DIR/$TOOLCHAIN_SYSROOT_DIR" ]; then
	echo "Copying sysroot from $TOOLCHAIN_DIR/$TOOLCHAIN_SYSROOT_DIR to $TARGET_ROOTFS..."
	rsync -a "$TOOLCHAIN_DIR/$TOOLCHAIN_SYSROOT_DIR/" "$TARGET_ROOTFS/"
else
	echo "Error: Sysroot directory '$TOOLCHAIN_DIR/$TOOLCHAIN_SYSROOT_DIR' does not exist." >&2
	exit 1
fi

# Define variables
export CHOST="${TARGET_CPU_ARCH}-buildroot-linux-gnu"
export LFS_TGT="${TARGET_CPU_ARCH}-buildroot-linux-gnu"
export CFLAGS="--sysroot=$TARGET_ROOTFS -I$TARGET_ROOTFS/usr/include"
export LDFLAGS="--sysroot=$TARGET_ROOTFS -L$TARGET_ROOTFS/usr/lib"
export PKG_CONFIG_PATH="$TARGET_ROOTFS/usr/lib/pkgconfig:$TARGET_ROOTFS/usr/share/pkgconfig"
export PKG_CONFIG_LIBDIR="$TARGET_ROOTFS/usr/lib/pkgconfig:$TARGET_ROOTFS/usr/share/pkgconfig"

# Compile M4
echo "Compiling M4 ${M4_VERSION}..."

tar -xf "$SOURCES_DIR/m4-${M4_VERSION}.tar.xz" -C "$SOURCES_DIR"

cd "$SOURCES_DIR/m4-${M4_VERSION}"

./configure \
	--host="${CHOST}" \
	--build=$(build-aux/config.guess) \
	--prefix=/usr || cat config.log

make -j$(nproc)

make DESTDIR="${TARGET_ROOTFS}" install

# Compile GCC
echo "Compiling GCC ${GCC_VERSION}..."

tar -xf "$SOURCES_DIR/gcc-${GCC_VERSION}.tar.xz" -C "$SOURCES_DIR"
tar -xf "$SOURCES_DIR/gmp-${GMP_VERSION}.tar.xz" -C "$SOURCES_DIR"
tar -xf "$SOURCES_DIR/mpfr-${MPFR_VERSION}.tar.xz" -C "$SOURCES_DIR"
tar -xf "$SOURCES_DIR/mpc-${MPC_VERSION}.tar.gz" -C "$SOURCES_DIR"

cd "$SOURCES_DIR/gcc-${GCC_VERSION}"

# Create symbolic links for GMP, MPFR, and MPC in the GCC source directory
ln -sf "../gmp-${GMP_VERSION}" gmp
ln -sf "../mpfr-${MPFR_VERSION}" mpfr
ln -sf "../mpc-${MPC_VERSION}" mpc

mkdir -p build

cd build

../configure \
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
	LDFLAGS_FOR_TARGET=-L$PWD/$LFS_TGT/libgcc || cat config.log

make -j$(nproc)

make DESTDIR="${TARGET_ROOTFS}" install
