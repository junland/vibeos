#!/bin/bash

set -e
set +h

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/_common.sh"

TARGET_CPU_ARCH=${1:-x86_64}

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

SOURCES_DIR=${SOURCES_DIR:-$(pwd)/sources}
STEPS_DIR=${STEPS_DIR:-$(pwd)/steps}
TARGET_ROOTFS_DIR=${TARGET_ROOTFS_DIR:-$(pwd)/rootfs}
TOOLCHAIN_DIR=${TOOLCHAIN_DIR:-${TARGET_ROOTFS_DIR}/opt/${TARGET_CPU_ARCH}-tools}
WORK_DIR=${WORK_DIR:-$(pwd)/work}
PATH="${TOOLCHAIN_DIR}/bin:$PATH"

export WORK_DIR SOURCES_DIR STEPS_DIR TOOLCHAIN_DIR TARGET_ROOTFS_DIR LFS_TGT PATH

# Setup required directories
msg "Preparing rootfs, work, and sources directories..."
ensure_dir "$SOURCES_DIR"
ensure_dir "$WORK_DIR"
ensure_dir "$TARGET_ROOTFS_DIR"
ensure_dir "$TOOLCHAIN_DIR"

# Ensure sbin, bin, and lib point to /usr equivalents in the target rootfs
msg "Creating rootfs compatibility symlinks..."
ensure_symlink "usr/sbin" "$TARGET_ROOTFS_DIR/sbin"
ensure_symlink "usr/bin" "$TARGET_ROOTFS_DIR/bin"
ensure_symlink "usr/lib" "$TARGET_ROOTFS_DIR/lib"

msg "Toolchain will be installed to: $TOOLCHAIN_DIR"
msg "Target root filesystem directory: $TARGET_ROOTFS_DIR"

#
# Start building components for the toolchain environment
#

msg "Loading step scripts from $STEPS_DIR..."

shopt -s nullglob
for step_script in "$STEPS_DIR"/*_step.sh; do
	# shellcheck source=/dev/null
	source "$step_script"
done
shopt -u nullglob

msg "Starting stage 1 build..."

step_toolchain_setup
step_binutils_pass1
step_gcc_pass1
step_linux_headers
step_glibc
step_gcc_libstdcxx

echo "Toolchain setup complete. Toolchain is located at $TOOLCHAIN_DIR"
