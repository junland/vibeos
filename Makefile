# Makefile for local debugging of the VibEOS bootstrap build pipeline.
# Mirrors the steps in .github/workflows/stage2.yml, stage3.yml, and stage3-chroot.yml.
#
# Usage:
#   make help             Show this help message
#   make deps             Install build dependencies (requires sudo)
#   make sources          Download source tarballs listed in data/bootstrap-sources.list
#   make stage1           Download and set up the cross-compilation toolchain
#   make stage2           Cross-compile and assemble the stage-2 root filesystem
#   make stage3-setup     Copy stage-3 scripts and sources into the rootfs
#   make stage3-chroot    Run the stage-3 build inside a chroot (requires sudo)
#   make stage3-docker    Run the stage-3 build inside Docker
#   make clean            Remove generated build artifacts

# ---------------------------------------------------------------------------
# Configurable variables — override on the command line, e.g.:
#   make stage2 ARCH=aarch64
# ---------------------------------------------------------------------------
ARCH            ?= x86_64
TOOLCHAIN_DIR   ?= $(CURDIR)/.toolchains/$(ARCH)-tools
ROOTFS_DIR      ?= $(CURDIR)/rootfs
SOURCES_DIR     ?= $(CURDIR)/sources
WORK_DIR        ?= $(CURDIR)/work
STEPS_DIR       ?= $(CURDIR)/steps
DOCKER_IMAGE    ?= vibeos:$(ARCH)-latest
DOCKER_REPO      = $(word 1,$(subst :, ,$(DOCKER_IMAGE)))

# ---------------------------------------------------------------------------
# Phony targets
# ---------------------------------------------------------------------------
.PHONY: help deps sources stage1 stage2 stage3-setup stage3-chroot stage3-docker \
        stage3-mount stage3-umount clean

# ---------------------------------------------------------------------------
# help
# ---------------------------------------------------------------------------
help:
	@echo ""
	@echo "VibEOS bootstrap build — local debugging targets"
	@echo ""
	@echo "  make deps             Install build dependencies (requires sudo)"
	@echo "  make sources          Download source tarballs"
	@echo "  make stage1           Set up the cross-compilation toolchain"
	@echo "  make stage2           Build the stage-2 root filesystem"
	@echo "  make stage3-setup     Copy stage-3 scripts into the rootfs"
	@echo "  make stage3-chroot    Run the stage-3 build inside a chroot (requires sudo)"
	@echo "  make stage3-docker    Run the stage-3 build inside Docker"
	@echo "  make clean            Remove generated build artifacts"
	@echo ""
	@echo "Configurable variables (current values):"
	@echo "  ARCH          = $(ARCH)"
	@echo "  TOOLCHAIN_DIR = $(TOOLCHAIN_DIR)"
	@echo "  ROOTFS_DIR    = $(ROOTFS_DIR)"
	@echo "  SOURCES_DIR   = $(SOURCES_DIR)"
	@echo "  DOCKER_IMAGE  = $(DOCKER_IMAGE)"
	@echo ""

# ---------------------------------------------------------------------------
# deps — install build dependencies (mirrors the CI apt-get step)
# ---------------------------------------------------------------------------
deps:
	sudo apt-get update
	sudo apt-get install -y \
	    unzip tree wget curl make m4 rsync gawk \
	    autoconf automake libtool pkg-config sudo \
	    xz-utils build-essential texinfo dos2unix

# ---------------------------------------------------------------------------
# sources — download source tarballs
# ---------------------------------------------------------------------------
sources:
	mkdir -p "$(SOURCES_DIR)"
	wget -nv --tries=25 --waitretry=25 \
	    -i data/bootstrap-sources.list \
	    -P "$(SOURCES_DIR)"

# ---------------------------------------------------------------------------
# stage1 — download and set up the cross-compilation toolchain
# ---------------------------------------------------------------------------
stage1:
	chmod +x stage1-toolchain.sh
	INSTALL_DIR="$(CURDIR)/.toolchains" \
	    ./stage1-toolchain.sh "$(ARCH)"
	@echo "Toolchain contents:"
	ls -la "$(TOOLCHAIN_DIR)"

# ---------------------------------------------------------------------------
# stage2 — cross-compile and assemble the stage-2 root filesystem
# ---------------------------------------------------------------------------
stage2:
	chmod +x _common.sh stage2-rootfs-setup.sh
	SOURCES_DIR="$(SOURCES_DIR)" \
	STEPS_DIR="$(STEPS_DIR)" \
	WORK_DIR="$(WORK_DIR)" \
	    ./stage2-rootfs-setup.sh \
	        "$(TOOLCHAIN_DIR)" \
	        "$(ARCH)" \
	        "$(ROOTFS_DIR)"

# ---------------------------------------------------------------------------
# stage3-setup — copy stage-3 scripts and sources into the rootfs
# (mirrors the "Run stage 3 build script to setup the rootfs" CI step)
# ---------------------------------------------------------------------------
stage3-setup:
	chmod +x stage3-rootfs.sh
	dos2unix stage3-rootfs.sh steps/*.sh _common.sh
	sudo ./stage3-rootfs.sh "$(ROOTFS_DIR)"

# ---------------------------------------------------------------------------
# stage3-mount / stage3-umount — helpers for chroot virtual filesystems
# ---------------------------------------------------------------------------
stage3-mount:
	sudo mkdir -p "$(ROOTFS_DIR)"/{proc,sys,dev/pts,run}
	sudo mount -t proc    proc    "$(ROOTFS_DIR)/proc"
	sudo mount -t sysfs   sysfs   "$(ROOTFS_DIR)/sys"
	sudo mount --bind     /dev    "$(ROOTFS_DIR)/dev"
	sudo mount -t devpts  devpts  "$(ROOTFS_DIR)/dev/pts"
	sudo mount -t tmpfs   tmpfs   "$(ROOTFS_DIR)/run"
    sudo mknod -m 600 "$(ROOTFS_DIR)/dev/console" c 5 1
    sudo mknod -m 666 "$(ROOTFS_DIR)/dev/null" c 1 3

stage3-umount:
	-sudo umount -lf "$(ROOTFS_DIR)/run"     2>/dev/null || true
	-sudo umount -lf "$(ROOTFS_DIR)/dev/pts" 2>/dev/null || true
	-sudo umount -lf "$(ROOTFS_DIR)/dev"     2>/dev/null || true
	-sudo umount -lf "$(ROOTFS_DIR)/sys"     2>/dev/null || true
	-sudo umount -lf "$(ROOTFS_DIR)/proc"    2>/dev/null || true

# ---------------------------------------------------------------------------
# stage3-chroot — run the stage-3 build inside a chroot
# ---------------------------------------------------------------------------
stage3-chroot: stage3-mount
	sudo chroot "$(ROOTFS_DIR)" /opt/stage3-rootfs.sh
	$(MAKE) stage3-umount

# ---------------------------------------------------------------------------
# stage3-docker — run the stage-3 build inside Docker
# ---------------------------------------------------------------------------
stage3-docker:
	@ARTIFACT=$$(find . -maxdepth 1 -name "rootfs-stage2-$(ARCH)-*.tar.xz" | head -1); \
	if [ -z "$$ARTIFACT" ]; then \
	    echo "Error: No rootfs-stage2-$(ARCH)-*.tar.xz found."; \
	    echo "Pack the stage-2 rootfs first, e.g.:"; \
	    echo "  tar -C $(ROOTFS_DIR) -cJf rootfs-stage2-$(ARCH)-local.tar.xz ."; \
	    exit 1; \
	fi; \
	echo "Importing $$ARTIFACT as $(DOCKER_IMAGE)..."; \
	docker import "$$ARTIFACT" "$(DOCKER_IMAGE)"; \
	docker images "$(DOCKER_REPO)"
	docker run -t --rm -w /opt "$(DOCKER_IMAGE)" /opt/stage3-rootfs.sh

# ---------------------------------------------------------------------------
# clean — remove generated build artifacts
# ---------------------------------------------------------------------------
clean:
	@echo "Removing generated build artifacts..."
	sudo rm -rf "$(ROOTFS_DIR)" "$(WORK_DIR)" .toolchains *.tar.xz
	@echo "Leaving $(SOURCES_DIR) intact. Remove it manually if needed."
