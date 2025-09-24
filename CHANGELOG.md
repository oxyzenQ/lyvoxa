# 📋 Lyvoxa Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [2.0.0] - Stellar Edition - 2025-09-24

### 🌟 Major Features
- New features will be documented here



### Planning

- Network monitoring enhancements
- Process tree view improvements
- ArchLinux AUR package integration

## [2.0.0] - Stellar Edition Universal - 2025-01-24

### 🌟 Major Overhaul

- **ArchLinux Optimization**: Native support with integration
- **Universal SHA256**: Simplified to industry-standard SHA256 checksums only
- **Universal Linux**: Single tgz package for all Linux x86_64 distributions
- **Streamlined Security**: Removed complexity while maintaining strong integrity verification

### 🔐 Security Improvements

- **SHA256 Standard**: Universal checksum algorithm supported everywhere
- **Reproducible Builds**: Consistent build environment and dependency locking
- **Memory Safety**: Leveraging Rust's built-in security guarantees
- **Simplified Verification**: Easy-to-follow verification process

### 🏗️ Architecture Changes

- **Single Package Format**: Focus on universal Linux tgz for maximum compatibility
- **ArchLinux First**: Optimized for ArchLinux users
- **Removed Complexity**: Eliminated multiple package formats for simplicity
- **Professional Polish**: Enhanced documentation and user experience

### 📦 Platform Support

- **ArchLinux**: Primary platform with native tooling support
- **Linux x86_64**: Universal compatibility across all distributions
- **Package Managers**: Native support for modern package management

## [1.5.0] - Stellar Edition Legacy - 2025-01-24

### 🌟 Major Features

- **Enterprise-Grade Security**: Multi-algorithm checksums and SSH signature verification
- **Professional Packaging**: Automated tar.gz creation with installation scripts
- **Portfolio-Ready Release Process**: Comprehensive CI/CD pipeline with security verification
- **Build System Optimization**: CPU core limiting and heat control for developer machines

### 🔐 Security Enhancements (Legacy)

- **Multi-Checksum Verification**: SHA512, BLAKE3, and ChaCha20-HMAC for integrity
- **SSH Signature Signing**: Cryptographic proof of authenticity for all releases
- **Supply Chain Security**: Automated verification in CI/CD pipeline
- **Comprehensive Documentation**: Detailed security verification guides

_Note: This approach was simplified in v2.0.0 to use universal SHA256 standard_

### ⚡ Performance Improvements

- **Optimized Build Profiles**: Enhanced Cargo.toml with multiple build configurations
- **CPU Core Management**: Limited to 3 cores for heat control during development
- **Incremental Compilation**: Faster rebuilds with sccache integration
- **Native CPU Optimization**: Target-specific optimizations for x86_64

### 🛠️ Developer Experience

- **Build Automation**: Professional build.sh script with progress logging
- **Make Integration**: Comprehensive Makefile with all common tasks
- **Docker Support**: Multi-stage containerization with CPU limits
- **GitHub Actions**: Complete CI/CD pipeline with quality checks

### 📦 Infrastructure

- **Reproducible Builds**: Locked Rust toolchain and dependency management
- **Cross-Platform Ready**: Future-proof structure for macOS support
- **Professional Documentation**: README, SECURITY.md, and setup guides
- **Quality Assurance**: Clippy, rustfmt, and automated testing

### 🎯 Portfolio Highlights

- **Security-First Approach**: Demonstrates understanding of cryptographic verification
- **Enterprise Practices**: Professional release management and documentation
- **Modern Tooling**: Latest Rust ecosystem tools and best practices
- **Scalable Architecture**: Extensible for future platforms and features

## [0.1.0] - Initial Release

### Added

- Basic system monitoring functionality
- Terminal user interface with ratatui
- CPU and memory monitoring
- Process listing and management
- Cross-platform support (Linux, macOS, Windows)

### Dependencies

- `sysinfo` - System information gathering
- `ratatui` - Terminal user interface
- `crossterm` - Cross-platform terminal handling
- `tokio` - Async runtime
- `chrono` - Date and time handling
- `humansize` - Human-readable size formatting

---

## Release Naming Convention

Lyvoxa uses themed release names to reflect the project's vision of high-performance monitoring:

- **Stellar Series**: Focus on performance and optimization
- **Future Series**: Matrix, Quantum, Dark (planned)

## Security Notice

**v2.0.0 and onwards:**

- SHA256 checksum verification (universal standard)
- Reproducible builds with locked toolchain
- ArchLinux and Linux x86_64 universal compatibility

**v2.0.0 (Legacy):**

- Multi-algorithm checksum verification
- SSH signature authentication
- Comprehensive security documentation

For verification instructions, see [SECURITY.md](SECURITY.md).

---

**Maintained by**: rezky_nightky | **License**: GPL-3.0 | **Repository**: [oxyzenQ/lyvoxa](https://github.com/oxyzenQ/lyvoxa)
