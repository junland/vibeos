#!/bin/bash

set -e
set +h

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/_common.sh"

TARGET_ROOTFS_DIR=$1

if [ -z "$TARGET_ROOTFS_DIR" ]; then
	msg "Usage: $0 <target-rootfilesystem-directory>" >&2
	exit 1
fi

if [ ! -d "$TARGET_ROOTFS_DIR" ]; then
	msg "Error: Target root filesystem directory '$TARGET_ROOTFS_DIR' does not exist." >&2
	exit 1
fi

# Copy the script itself and its dependencies into the target directory so it
# can be run inside the chroot environment.
msg "Copying stage3 script and dependencies to $TARGET_ROOTFS_DIR..."

cp -v "$SCRIPT_DIR/stage3-rootfs-build.sh" "$TARGET_ROOTFS_DIR/stage3-rootfs-build.sh"
chmod +x "$TARGET_ROOTFS_DIR/stage3-rootfs-build.sh"

cp -v "$SCRIPT_DIR/_common.sh" "$TARGET_ROOTFS_DIR/_common.sh"

cp -rv "$SCRIPT_DIR/steps" "$TARGET_ROOTFS_DIR/steps"

msg "Stage 3 script copied to $TARGET_ROOTFS_DIR. You can now run it inside the chroot."