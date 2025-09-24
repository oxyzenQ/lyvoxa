# 📦 Lyvoxa Installation Guide for Arch Linux

This guide explains how to properly install Lyvoxa on Arch Linux systems.

## 🚨 The Issue You Encountered

The release `.tar.zst` file from GitHub is a **regular compressed tarball**, not an Arch Linux package. That's why `pacman -U` failed with:

```
error: missing package metadata in lyvoxa-Stellar-2.0-linux-x86_64.tar.zst
error: 'lyvoxa-Stellar-2.0-linux-x86_64.tar.zst': invalid or corrupted package
```

Pacman expects `.pkg.tar.zst` files with proper PKGINFO metadata, not generic tarballs.

## ✅ Correct Installation Methods

### Method 1: Extract and Use Binaries Directly

**For immediate use without system integration:**

```bash
# Download and verify
curl -LO https://github.com/oxyzenQ/lyvoxa/releases/download/Stellar-2.0/lyvoxa-Stellar-2.0-linux-x86_64.tar.zst
curl -LO https://github.com/oxyzenQ/lyvoxa/releases/download/Stellar-2.0/lyvoxa-Stellar-2.0-linux-x86_64.tar.zst.sha256

# Verify integrity
sha256sum -c lyvoxa-Stellar-2.0-linux-x86_64.tar.zst.sha256

# Extract
tar --zstd -xvf lyvoxa-Stellar-2.0-linux-x86_64.tar.zst

# Run directly
./lyvoxa --version
./lyvoxa-simple --version

# Optional: Copy to PATH
sudo cp lyvoxa lyvoxa-simple /usr/local/bin/
```

### Method 2: Build Proper Arch Package (Recommended)

**For system integration with pacman:**

```bash
# Clone repository
git clone https://github.com/oxyzenQ/lyvoxa.git
cd lyvoxa

# Build Arch packages
make arch-pkg

# Install the package you prefer
sudo pacman -U lyvoxa-2.0.0-1-x86_64.pkg.tar.zst        # Source-built (optimized)
# OR
sudo pacman -U lyvoxa-bin-2.0.0-1-x86_64.pkg.tar.zst    # Pre-built binaries (faster)
```

### Method 3: Manual PKGBUILD (Advanced)

**If you want to customize the build:**

```bash
# Use the provided PKGBUILD
cd lyvoxa
makepkg -si    # Build and install source package

# OR use binary PKGBUILD
cp PKGBUILD-bin PKGBUILD
makepkg -si    # Build and install binary package
```

## 📋 Package Comparison

| Method | Type | Installation Speed | Runtime Performance | System Integration |
|--------|------|-------------------|-------------------|-------------------|
| **Extract Binary** | Direct | ⚡ Instant | 🔥 Good | ❌ None |
| **Source Package** | PKGBUILD | 🐌 Slow (compile) | 🚀 Best (native) | ✅ Full |
| **Binary Package** | PKGBUILD | ⚡ Fast | 🔥 Good | ✅ Full |

## 🎯 Recommendations

### For Daily Use:
```bash
# Quick installation with system integration
make arch-pkg-binary
sudo pacman -U lyvoxa-bin-*.pkg.tar.zst
```

### For Maximum Performance:
```bash
# Compile with native optimizations
make arch-pkg-source  
sudo pacman -U lyvoxa-*.pkg.tar.zst
```

### For Testing/Development:
```bash
# Extract and run directly
tar --zstd -xvf lyvoxa-Stellar-2.0-linux-x86_64.tar.zst
./lyvoxa
```

## 🔧 Available Commands After Installation

```bash
# Main TUI application
lyvoxa

# Lightweight version
lyvoxa-simple

# Check version
lyvoxa --version

# View help
lyvoxa --help
```

## 🗑️ Uninstallation

```bash
# If installed via pacman
sudo pacman -R lyvoxa      # Source package
sudo pacman -R lyvoxa-bin  # Binary package

# If copied to /usr/local/bin
sudo rm /usr/local/bin/lyvoxa /usr/local/bin/lyvoxa-simple
```

## 🛠️ Building Your Own Package

The repository includes everything needed:

```bash
# Available make targets
make arch-pkg           # Build both source and binary packages
make arch-pkg-source    # Build source package only  
make arch-pkg-binary    # Build binary package only
make arch-pkg-clean     # Clean build artifacts

# Or use the script directly
./build-arch-pkg.sh both     # Build both
./build-arch-pkg.sh source   # Source only
./build-arch-pkg.sh binary   # Binary only  
./build-arch-pkg.sh clean    # Clean up
```

## 🔍 Package Contents

Both packages install:
- `/usr/bin/lyvoxa` - Main TUI application
- `/usr/bin/lyvoxa-simple` - Lightweight version
- `/usr/share/doc/lyvoxa/` - Documentation
- `/usr/share/licenses/lyvoxa/` - License files

The source package additionally includes:
- Shell completions (if available)
- Man pages (if available)
- Optimized binaries for your specific CPU

---

**Need Help?** Open an issue at: https://github.com/oxyzenQ/lyvoxa/issues
