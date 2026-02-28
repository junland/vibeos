#!/bin/bash
# flit-core Step - Build and install flitcore in chroot

PYTHON_FLIT_CORE_VER="3.12.0"

step_chroot_python_flit_core() {
	extract_file "${SOURCES_DIR}/flit_core-${PYTHON_FLIT_CORE_VER}.tar.gz" "${WORK_DIR}/flit_core-${PYTHON_FLIT_CORE_VER}"

	cd "${WORK_DIR}/flit_core-${PYTHON_FLIT_CORE_VER}"

	msg "Building flit-core..."

	pip3 wheel -w dist --no-cache-dir --no-build-isolation --no-deps $PWD

	msg "Installing flit-core..."
	
	pip3 install --no-index --find-links dist flit_core

	clean_dir ${WORK_DIR}
}
