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

# Fix absolute paths in GNU ld linker scripts from the toolchain's sysroot.
# These scripts (e.g. libc.so) contain hardcoded absolute paths like
# /lib64/libc.so.6 which break when libtool does not pass --sysroot to the
# linker.  Converting them to bare filenames lets the linker resolve them
# through its search path instead.
msg "Fixing absolute paths in sysroot linker scripts..."
for f in "$TARGET_ROOTFS"/usr/lib/*.so "$TARGET_ROOTFS"/usr/lib64/*.so "$TARGET_ROOTFS"/lib/*.so "$TARGET_ROOTFS"/lib64/*.so; do
	[ -f "$f" ] || continue
	if grep -qE 'GROUP|INPUT|AS_NEEDED' "$f" 2>/dev/null; then
		msg "Fixing linker script: $f"
		sed -i \
			-e 's|/usr/lib64/||g' \
			-e 's|/usr/lib/||g' \
			-e 's|/lib64/||g' \
			-e 's|/lib/||g' \
			"$f"
	fi
done

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

msg "Create compatibility for lib64..."

ln -sv usr/lib "$TARGET_ROOTFS/lib64"
ln -sv lib "$TARGET_ROOTFS/usr/lib64"

for compile_script in "$SCRIPT_DIR"/stage2/compile-*.sh; do
	source "$compile_script"
done

compile_m4
compile_ncurses
compile_bash
compile_coreutils
compile_diffutils
compile_file
compile_findutils
compile_gawk
compile_grep
compile_gzip
compile_make
compile_patch
compile_sed
compile_tar
compile_xz
compile_binutils
compile_gcc
