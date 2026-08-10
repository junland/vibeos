#!/bin/bash

set -e
set +h

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/_common.sh"

TARGET_CPU_ARCH="${1:-x86_64}"
TARGET_ROOTFS_DIR="${2:-${TARGET_ROOTFS_DIR:-$(pwd)/rootfs}}"

case "$TARGET_CPU_ARCH" in
	x86_64 | x86-64 | amd64 | x64)
		LFS_TGT="x86_64-buildroot-linux-gnu"
		;;
	arm64 | aarch64)
		LFS_TGT="aarch64-buildroot-linux-gnu"
		;;
	*)
		msg "Unsupported target architecture: $TARGET_CPU_ARCH" >&2
		exit 1
		;;
esac

SOURCES_DIR="${SOURCES_DIR:-$(pwd)/sources}"
STEPS_DIR="${STEPS_DIR:-$(pwd)/steps}"
TOOLCHAIN_DIR="${TOOLCHAIN_DIR:-${TARGET_ROOTFS_DIR}/opt/${TARGET_CPU_ARCH}-tools}"
WORK_DIR="${WORK_DIR:-$(pwd)/work}"
PATH="$TOOLCHAIN_DIR/bin:$PATH"

export WORK_DIR SOURCES_DIR STEPS_DIR TOOLCHAIN_DIR TARGET_ROOTFS_DIR LFS_TGT PATH

msg "PATH set to: $PATH"

# Ensure required directories exist
ensure_dir "$SOURCES_DIR"
ensure_dir "$TARGET_ROOTFS_DIR"
ensure_dir "$TARGET_ROOTFS_DIR/tmp"
ensure_dir "$WORK_DIR"

# Ensure sbin, bin, and lib point to /usr equivalents in the target rootfs
msg "Creating rootfs compatibility symlinks..."
ensure_symlink "usr/sbin" "$TARGET_ROOTFS_DIR/sbin"
ensure_symlink "usr/bin" "$TARGET_ROOTFS_DIR/bin"
ensure_symlink "usr/lib" "$TARGET_ROOTFS_DIR/lib"

msg "Toolchain will be installed to: $TOOLCHAIN_DIR"
msg "Target root filesystem directory: $TARGET_ROOTFS_DIR"

#
# Start building components for the chroot environment
#

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
