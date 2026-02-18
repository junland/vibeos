#!/bin/bash

set -e

TOOLCHAIN_URL="${TOOLCHAIN_URL:-https://toolchains.bootlin.com/downloads/releases/toolchains}"
TOOLCHAIN_VER="${TOOLCHAIN_VER:-glibc--bleeding-edge-2025.08-1}"

# Identify the target arch based on the first argument, defaulting to x86_64
TARGET_ARCH="${1:-x86_64}"

case "$TARGET_ARCH" in
x86-64 | x86_64 | amd64 | x64)
	TOOLCHAIN_FULL_URL="$TOOLCHAIN_URL/x86-64/tarballs/x86-64--${TOOLCHAIN_VER}.tar.xz"
	;;
arm64 | aarch64)
	TOOLCHAIN_FULL_URL="$TOOLCHAIN_URL/aarch64/tarballs/aarch64--${TOOLCHAIN_VER}.tar.xz"
	;;
*)
	echo "Unsupported target architecture: $TARGET_ARCH" >&2
	exit 1
	;;
esac

TOOLCHAIN_EXTRACT_DIR="${INSTALL_DIR:-${PWD}/.toolchains}/$(basename "$TOOLCHAIN_FULL_URL" .tar.xz)"

if [ -d "$TOOLCHAIN_EXTRACT_DIR" ]; then
	echo "Toolchain already exists at $TOOLCHAIN_EXTRACT_DIR, skipping download and extraction."
else
	echo "Downloading toolchain from $TOOLCHAIN_FULL_URL..."
	wget -nv -O toolchain.tar.xz "$TOOLCHAIN_FULL_URL"

	echo "Extracting toolchain to $TOOLCHAIN_EXTRACT_DIR..."
	mkdir -p "$TOOLCHAIN_EXTRACT_DIR"
	tar -xf toolchain.tar.xz -C "$TOOLCHAIN_EXTRACT_DIR" --strip-components=1

	echo "Cleaning up downloaded toolchain archive..."
	rm toolchain.tar.xz
fi

# Make sure to run the toolchain's setup script if it exists
if [ -f "$TOOLCHAIN_EXTRACT_DIR/relocate-sdk.sh" ]; then
	echo "Running toolchain setup script..."
	"$TOOLCHAIN_EXTRACT_DIR/relocate-sdk.sh" "$TOOLCHAIN_EXTRACT_DIR" 
fi

echo "Toolchain setup complete. Toolchain is located at $TOOLCHAIN_EXTRACT_DIR"

