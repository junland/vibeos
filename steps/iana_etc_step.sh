#!/bin/bash
# IANA ETC Step - Install IANA network and services data

IANA_ETC_VER="20250807"

step_chroot_iana_etc() {
	msg "Installing IANA network and services data files..."

	extract_file "${SOURCES_DIR}/iana-etc-${IANA_ETC_VER}.tar.gz" "${WORK_DIR}/iana-etc-${IANA_ETC_VER}"

	cd "${WORK_DIR}/iana-etc-${IANA_ETC_VER}"

	cp -v services protocols "${TARGET_ROOTFS_PATH}/etc/"

	clean_work_dir
}
