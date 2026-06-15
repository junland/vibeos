#!/bin/bash

set -e
set +h

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/_common.sh"

TOOLCHAIN_DIR="${1:-}"
TARGET_CPU_ARCH="${2:-x86_64}"
TARGET_ROOTFS_DIR="${3:-}"

SOURCES_DIR="${SOURCES_DIR:-$(pwd)/sources}"
STEPS_DIR="${STEPS_DIR:-$(pwd)/steps}"
WORK_DIR="${WORK_DIR:-$(pwd)/work}"
LFS_TGT="${TARGET_CPU_ARCH}-buildroot-linux-gnu"
PATH="$TOOLCHAIN_DIR/bin:$PATH"

export WORK_DIR SOURCES_DIR TARGET_ROOTFS_DIR TOOLCHAIN_DIR LFS_TGT PATH

if [ -z "$TOOLCHAIN_DIR" ] || [ -z "$TARGET_ROOTFS_DIR" ]; then
	msg "Usage: $0 <toolchain-directory> [target-cpu-arch] <target-rootfilesystem>" >&2
	exit 1
fi

if [ ! -d "$TOOLCHAIN_DIR" ]; then
	msg "Error: Toolchain directory '$TOOLCHAIN_DIR' does not exist." >&2
	exit 1
fi

msg "PATH set to: $PATH"

# Setup required directories
msg "Preparing rootfs, work, and sources directories..."
ensure_dir "$SOURCES_DIR"
ensure_dir "$TARGET_ROOTFS_DIR"
ensure_dir "$TARGET_ROOTFS_DIR/tmp"
ensure_dir "$WORK_DIR"

# Ensure sbin, bin, and lib point to /usr equivalents in the target rootfs
msg "Creating rootfs compatibility symlinks..."
ensure_symlink "usr/sbin" "$TARGET_ROOTFS_DIR/sbin"
ensure_symlink "usr/bin" "$TARGET_ROOTFS_DIR/bin"
ensure_symlink "usr/lib" "$TARGET_ROOTFS_DIR/lib"

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
