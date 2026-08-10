# VibeOS

An independent, custom Linux distribution designed for server environments. VibeOS is a personal experimental project and community-driven open-source OS that enables users to build a minimal, tailored Linux system from source.

**Status**: 🚧 **Alpha** — Core infrastructure in development

## Overview

VibeOS provides a three-stage bootstrap build system for creating a minimal, production-ready Linux distribution. The build pipeline is modular and extensible, allowing customization at each stage to support various server workloads and deployment scenarios.

### Supported Architectures

- **x86_64** ✓
- **aarch64** (ARM64) ✓
- Additional architectures can be added by extending the build pipeline

## Quick Start

The project uses a Makefile-based build system for local debugging and development. To get started:

```bash
# View available build targets and current configuration
make help

# Install build dependencies (Linux systems only)
make deps

# Download source tarballs
make sources

# Run the complete build pipeline
make stage1      # Set up the cross-compilation toolchain
make stage2      # Build the stage-2 root filesystem
make stage3-setup  # Copy stage-3 scripts into the rootfs
make stage3-docker # Run stage-3 inside Docker (or make stage3-chroot for chroot)

# Clean generated artifacts
make clean
```

### Common Configuration Variables

Override these on the command line:

```bash
# Specify target architecture
make stage2 ARCH=aarch64

# Specify custom directories
make stage2 SOURCES_DIR=/path/to/sources ROOTFS_DIR=/path/to/rootfs
```

See `make help` for all available options.

## Build Stages Explained

VibEOS uses a three-stage bootstrap approach:

### Stage 1: Cross-Compilation Toolchain
Prepares the cross-compilation toolchain needed to build binaries for the target architecture on the host machine.

**Target**: `make stage1`

### Stage 2: Root Filesystem Assembly
Cross-compiles essential system components (libc, busybox, kernel, etc.) and assembles them into a minimal root filesystem.

**Target**: `make stage2`

### Stage 3: Native Build Environment
Runs a native build inside the stage-2 rootfs (via chroot or Docker) to complete the OS with additional packages and configurations.

**Targets**:
- `make stage3-chroot` — Run inside a chroot (requires sudo)
- `make stage3-docker` — Run inside a Docker container (recommended for isolation)

## Contributing

We welcome contributions! Whether you're fixing bugs, improving documentation, or adding features, please:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/your-feature`)
3. Commit your changes with clear messages
4. Push to the branch and open a Pull Request
5. Provide context and motivation for your changes

### Areas We'd Love Help With

- Performance optimizations
- Additional architecture support
- Documentation improvements
- Testing and bug reports
- Package selection and integration

## License

Please see the [LICENSE](LICENSE) file for details.

## References

- [Linux From Scratch (LFS)](http://www.linuxfromscratch.org/) — Educational guide
- [GNU toolchain documentation](https://sourceware.org/binutils/docs/)
- GitHub Workflows — CI/CD configuration in `.github/workflows/` for automated builds
