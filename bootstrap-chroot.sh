#!/bin/bash

set -e

TOOLCHAIN_DIR=$1
TARGET_CPU_ARCH=${2:-x86_64}
TARGET_ROOTFS=$3

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

# Setup the target root filesystem for the chroot environment
if [ ! -d "$TARGET_ROOTFS" ]; then
	# Create the target root filesystem directory if it doesn't exist
	mkdir -p "$TARGET_ROOTFS"
fi

# Copy sysroot contents to the target root filesystem
if [ -d "$TOOLCHAIN_DIR/$TOOLCHAIN_SYSROOT_DIR" ]; then
	echo "Copying sysroot from $TOOLCHAIN_DIR/$TOOLCHAIN_SYSROOT_DIR to $TARGET_ROOTFS..."
	rsync -a --exclude='*.o' --exclude='*.a' --exclude='*~' "$TOOLCHAIN_DIR/$TOOLCHAIN_SYSROOT_DIR/" "$TARGET_ROOTFS/"
else
	echo "Error: Sysroot directory '$TOOLCHAIN_DIR/$TOOLCHAIN_SYSROOT_DIR' does not exist." >&2
	exit 1
fi
