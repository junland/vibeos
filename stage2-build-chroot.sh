#!/bin/bash

set -e
set +h

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/_common.sh"

TOOLCHAIN_DIR=$1
TARGET_CPU_ARCH=${2:-x86_64}
TARGET_ROOTFS_DIR=$3

SOURCES_DIR=${SOURCES_DIR:-$(pwd)/sources}
STEPS_DIR=${STEPS_DIR:-$(pwd)/steps}
WORK_DIR=${WORK_DIR:-$(pwd)/work}

export WORK_DIR SOURCES_DIR TARGET_ROOTFS_DIR

if [ -z "$TOOLCHAIN_DIR" ] || [ -z "$TARGET_ROOTFS_DIR" ]; then
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
if [ ! -d "$TARGET_ROOTFS_DIR" ]; then
	# Create the target root filesystem directory if it doesn't exist
	mkdir -p "$TARGET_ROOTFS_DIR"
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
	msg "Copying sysroot from $TOOLCHAIN_DIR/$TOOLCHAIN_SYSROOT_DIR to $TARGET_ROOTFS_DIR..."
	rsync -a "$TOOLCHAIN_DIR/$TOOLCHAIN_SYSROOT_DIR/" "$TARGET_ROOTFS_DIR/"
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
for f in "$TARGET_ROOTFS_DIR"/usr/lib/*.so "$TARGET_ROOTFS_DIR"/usr/lib64/*.so "$TARGET_ROOTFS_DIR"/lib/*.so "$TARGET_ROOTFS_DIR"/lib64/*.so; do
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
export CFLAGS="--sysroot=$TARGET_ROOTFS_DIR -I$TARGET_ROOTFS_DIR/usr/include"
export LDFLAGS="--sysroot=$TARGET_ROOTFS_DIR -L$TARGET_ROOTFS_DIR/usr/lib"
export PKG_CONFIG_PATH="$TARGET_ROOTFS_DIR/usr/lib/pkgconfig:$TARGET_ROOTFS_DIR/usr/share/pkgconfig"
export PKG_CONFIG_LIBDIR="$TARGET_ROOTFS_DIR/usr/lib/pkgconfig:$TARGET_ROOTFS_DIR/usr/share/pkgconfig"

#
# Start building components in the for the chroot environment
#

msg "Create compatibility for lib64..."

ln -sv usr/lib "$TARGET_ROOTFS_DIR/lib64"
ln -sv lib "$TARGET_ROOTFS_DIR/usr/lib64"

for step_script in "$STEPS_DIR"/*_step.sh; do
	source "$step_script"
done

msg "Starting stage 2 build..."

step_m4
step_ncurses
step_bash
step_coreutils
step_diffutils
step_file
step_findutils
step_gawk
step_grep
step_gzip
step_make
step_patch
step_sed
step_tar
step_xz
step_binutils
step_gcc

msg "Completed stage 2 build..."