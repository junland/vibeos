#!/bin/bash

set -e
set +h

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/_common.sh"

TARGET_ROOTFS_DIR=$1

SOURCES_DIR=${SOURCES_DIR:-/sources}
WORK_DIR=${WORK_DIR:-/work}
STEPS_DIR=${STEPS_DIR:-"$SCRIPT_DIR/steps"}

export SOURCES_DIR WORK_DIR

if [ -n "$TARGET_ROOTFS_DIR" ]; then
	# Host mode: validate the target directory then copy the script and its
	# dependencies into it so the script can be executed inside the chroot.
	if [ ! -d "$TARGET_ROOTFS_DIR" ]; then
		msg "Error: Target root filesystem directory '$TARGET_ROOTFS_DIR' does not exist." >&2
		exit 1
	fi

	msg "Copying stage3 script and dependencies to $TARGET_ROOTFS_DIR..."

	cp -v "$SCRIPT_DIR/stage3-rootfs-build.sh" "$TARGET_ROOTFS_DIR/stage3-rootfs-build.sh"
	chmod +x "$TARGET_ROOTFS_DIR/stage3-rootfs-build.sh"

	cp -v "$SCRIPT_DIR/_common.sh" "$TARGET_ROOTFS_DIR/_common.sh"

	cp -rv "$SCRIPT_DIR/steps" "$TARGET_ROOTFS_DIR/steps"

	msg "Stage 3 script copied to $TARGET_ROOTFS_DIR. You can now run it inside the chroot."
else
	# Chroot mode: source all step scripts and run the stage3 chroot build.
	shopt -s nullglob
	for step_script in "$STEPS_DIR"/*_step.sh; do
		source "$step_script"
	done
	shopt -u nullglob

	msg "Starting stage 3 chroot build..."

	step_chroot_setup
	step_chroot_iana_etc
	step_chroot_glibc
	step_chroot_zlib
	step_chroot_bzip2
	step_chroot_xz
	step_chroot_zstd
	step_chroot_file
	step_chroot_readline
	step_chroot_m4
	step_chroot_flex
	step_chroot_pkgconf
	step_chroot_binutils
	step_chroot_gmp
	step_chroot_mpfr
	step_chroot_mpc
	step_chroot_attr
	step_chroot_acl
	step_chroot_libcap
	step_chroot_libxcrypt
	step_chroot_shadow
	step_chroot_gcc
	step_chroot_ncurses
	step_chroot_sed
	step_chroot_gettext
	step_chroot_bison
	step_chroot_bash
	step_chroot_libtool
	step_chroot_gdbm
	step_chroot_gperf
	step_chroot_expat
	step_chroot_inetutils
	step_chroot_less
	step_chroot_perl_stage2
	step_chroot_perl_xml_parser
	step_chroot_perl_stage3
	step_chroot_autoconf
	step_chroot_automake
	step_chroot_openssl
	step_chroot_kmod
	step_chroot_elfutils_lib
	step_chroot_libffi
	step_chroot_python_stage2
	step_chroot_python_flit_core
	step_chroot_python_wheel
	step_chroot_python_packaging
	step_chroot_python_setuptools
	step_chroot_python_stage3
	step_chroot_ninja
	step_chroot_meson
	step_chroot_coreutils
	step_chroot_diffutils
	step_chroot_gawk
	step_chroot_findutils
	step_chroot_groff
	step_chroot_gzip
	step_chroot_libpipeline
	step_chroot_make
	step_chroot_patch
	step_chroot_tar
	step_chroot_texinfo
	step_chroot_texinfo_stage3
	step_chroot_util_linux
	step_chroot_util_linux_stage3
	step_chroot_procps_ng
	step_chroot_tzdata
	step_chroot_cleanup

	msg "Completed stage 3 chroot build."
fi