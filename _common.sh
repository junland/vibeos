#!/bin/bash
# Common utility functions for bootstrap steps

# msg is a helper function that prints messages with a consistent format.
msg() {
	echo " ==> $*"
}

# #clean_dir is a helper function that cleans up a directory by removing all of its contents, while ensuring that the directory itself exists.
clean_dir() {
	cd "${1}" || return 1
	msg "Cleaning up directory at ${1}..."
	rm -rf "${1:?}"/*
}

# extract_file is a helper function that extracts various archive formats to a specified destination directory, with optional stripping of leading path components and verbose output.
extract_file() {
	local archive_file=$1
	local dest_dir=$2

	# Use environment variables with defaults
	local strip_components=${EXTRACT_FILE_STRIP_COMPONENTS:-0}
	local verbose=${EXTRACT_FILE_VERBOSE_EXTRACT:-false}

	# Make sure the archive file exists, if not find another archive file with a different extension.
	if [ ! -f "${archive_file}" ]; then
		msg "Archive file ${archive_file} does not exist, searching for alternative..."
		archive_file=$(find "${SOURCES}" -name "$(basename "${archive_file}" | sed 's/\.[^.]*$//').*" | head -1)
		if [ ! -f "${archive_file}" ]; then
			msg "Error: Archive file ${archive_file} does not exist."
			exit 1
		fi
		msg "Found alternative archive file: ${archive_file}"
	fi

	mkdir -vp "${dest_dir}"

	msg "Extracting to ${dest_dir}..."

	local verbose_flag=""
	if [ "${verbose}" = true ] || [ "${verbose}" = "true" ]; then
		verbose_flag="-v"
	fi

	# Check to see if we have to strip components based on whether the archive file has a parent directory
	if [ "${strip_components}" -eq 0 ]; then
		if tar -tf "${archive_file}" | head -1 | grep -q '/'; then
			msg "Archive has a parent directory, setting strip_components to 1"
			strip_components=1
		else
			msg "Archive does not have a parent directory, setting strip_components to 0"
			strip_components=0
		fi
	fi

	case ${archive_file} in
	*.tar.bz2 | *.tbz2)
		tar -xjf "${archive_file}" -C "${dest_dir}" --strip-components="${strip_components}" "${verbose_flag}"
		;;
	*.tar.xz | *.txz)
		tar -xJf "${archive_file}" -C "${dest_dir}" --strip-components="${strip_components}" "${verbose_flag}"
		;;
	*.tar.gz | *.tgz)
		tar -xzf "${archive_file}" -C "${dest_dir}" --strip-components="${strip_components}" "${verbose_flag}"
		;;
	*.zip)
		# Note: unzip does not support stripping leading path components like tar's --strip-components.
		# When strip_components is non-zero, we currently extract as-is and document the limitation.
		local unzip_flags=""
		if [ "${verbose}" = true ] || [ "${verbose}" = "true" ]; then
			unzip_flags="-v"
		else
			unzip_flags="-q"
		fi

		if [ "${strip_components}" -ne 0 ]; then
			msg "strip_components=${strip_components} requested, but unzip cannot strip path components; extracting with original paths."
		fi

		unzip ${unzip_flags} "${archive_file}" -d "${dest_dir}"
		;;
	*)
		msg "Unknown archive format: ${archive_file}"
		exit 1
		;;
	esac
}

# run_copnfigure is a helper function that runs the configure script with the provided arguments and checks for success.
run_configure() {
	# Verify that the current directory contains a configure script or a link to one
	if [ ! -f "configure" ] && [ ! -L "configure" ]; then
		msg "Error: No configure script found in the current directory (${PWD})."
		exit 1
	fi

	msg "Running configure with arguments: $@"

	if ./configure "$@"; then
		msg "Configure succeeded for ${PWD}."
	else
		msg "Error: Configure failed for ${PWD}. Printing config.log for debugging."
		cat config.log
		exit 1
	fi
}

# ensure_dir is a function that checks if a directory exists and creates it if it doesn't.
ensure_dir() {
	local dir="$1"
	[ -d "$dir" ] || mkdir -p "$dir"
}

# ensure_symlink is a function that creates a symbolic link, removing any existing file or link at the destination.
ensure_symlink() {
	local target="$1"
	local link_path="$2"
	rm -rf "$link_path"
	ln -sv "$target" "$link_path"
}

apply_patch() {
	local patch_file="$1"
	if [ ! -f "$patch_file" ]; then
		msg "Error: Patch file '$patch_file' does not exist."
		exit 1
	fi

	msg "Applying patch: $patch_file"
	patch -Np1 -i "$patch_file"
}