#!/bin/bash

set -e
set +h

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/_common.sh"

TOOLCHAIN_DIR=$1
TARGET_CPU_ARCH=${2:-x86_64}
TARGET_ROOTFS_DIR=$3

SOURCES_DIR=${SOURCES_DIR:-$(pwd)/sources}
STEPS_DIR=${STEPS_DIR:-$(pwd)/steps}
WORK_DIR=${WORK_DIR:-$(pwd)/work}

export WORK_DIR SOURCES_DIR TARGET_ROOTFS_DIR TOOLCHAIN_DIR

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

# Define variables
export CHOST="${TARGET_CPU_ARCH}-buildroot-linux-gnu"
export LFS_TGT="${TARGET_CPU_ARCH}-buildroot-linux-gnu"

#
# Start building components for the chroot environment
#

# Make sure sbin, bin, and lib directories are symlinked to their new locations in the target root filesystem
msg "Creating symlinks for sbin, bin, and lib in target root filesystem..."
ln -sv usr/sbin "$TARGET_ROOTFS_DIR/sbin"
ln -sv usr/bin "$TARGET_ROOTFS_DIR/bin"
ln -sv usr/lib "$TARGET_ROOTFS_DIR/lib"

# Make sure that tmp directory exists
msg "Creating tmp directory..."
mkdir -p "$TARGET_ROOTFS_DIR/tmp"

msg "Loading step scripts from $STEPS_DIR..."

shopt -s nullglob
for step_script in "$STEPS_DIR"/*_step.sh; do
	# shellcheck source=/dev/null
	source "$step_script"
done
shopt -u nullglob

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
step_binutils_pass2
step_gcc_pass2

msg "Completed stage 2 build..."
