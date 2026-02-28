#!/bin/bash

set -e

TOOLCHAIN_URL="${TOOLCHAIN_URL:-https://toolchains.bootlin.com/downloads/releases/toolchains}"
TOOLCHAIN_VER="${TOOLCHAIN_VER:-glibc--bleeding-edge-2025.08-1}"

# Identify the target arch based on the first argument, defaulting to x86_64
TARGET_CPU_ARCH="${1:-x86_64}"

case "$TARGET_CPU_ARCH" in
x86-64 | x86_64 | amd64 | x64)
	TOOLCHAIN_FULL_URL="$TOOLCHAIN_URL/x86-64/tarballs/x86-64--${TOOLCHAIN_VER}.tar.xz"
	TOOLCHAIN_SYSROOT_DIR="x86_64-linux-gnu/sysroot"
	TOOLCHAIN_EXTRACT_PATH="${INSTALL_DIR:-${PWD}/.toolchains}/x86_64-tools"
	;;
arm64 | aarch64)
	TOOLCHAIN_FULL_URL="$TOOLCHAIN_URL/aarch64/tarballs/aarch64--${TOOLCHAIN_VER}.tar.xz"
	TOOLCHAIN_SYSROOT_DIR="aarch64-linux-gnu/sysroot"
	TOOLCHAIN_EXTRACT_PATH="${INSTALL_DIR:-${PWD}/.toolchains}/aarch64-tools"
	;;
*)
	echo "Unsupported target architecture: $TARGET_CPU_ARCH" >&2
	exit 1
	;;
esac

# Check if the toolchain already exists before downloading and extracting
if [ -d "$TOOLCHAIN_EXTRACT_PATH" ] && [ -f "$TOOLCHAIN_EXTRACT_PATH/.toolchain_extracted" ]; then
	echo "Toolchain already exists at $TOOLCHAIN_EXTRACT_PATH, skipping download and extraction."
else
	echo "Downloading toolchain from $TOOLCHAIN_FULL_URL..."
	wget -nv -O toolchain.tar.xz "$TOOLCHAIN_FULL_URL"

	echo "Extracting toolchain to $TOOLCHAIN_EXTRACT_PATH..."
	mkdir -p "$TOOLCHAIN_EXTRACT_PATH"
	tar -xf toolchain.tar.xz -C "$TOOLCHAIN_EXTRACT_PATH" --strip-components=1

	touch "$TOOLCHAIN_EXTRACT_PATH/.toolchain_extracted"

	echo "Cleaning up downloaded toolchain archive..."
	rm toolchain.tar.xz
fi

# Make sure to run the toolchain's setup script if it exists
if [ -f "$TOOLCHAIN_EXTRACT_PATH/relocate-sdk.sh" ]; then
	echo "Running toolchain setup script..."
	"$TOOLCHAIN_EXTRACT_PATH/relocate-sdk.sh" "$TOOLCHAIN_EXTRACT_PATH"
fi

echo "Toolchain setup complete. Toolchain is located at $TOOLCHAIN_EXTRACT_PATH"
