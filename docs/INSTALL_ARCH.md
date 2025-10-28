# 📦 Lyvoxa Installation Guide for Arch Linux

This guide explains how to properly install Lyvoxa on Arch Linux systems.

## 🚨 The Issue You Encountered

The release `.tar.gz` file from GitHub is a **regular compressed tarball**, not an Arch Linux package. That's why `pacman -U` failed with:

```text
error: missing package metadata in lyvoxa-Stellar-2.0-linux-x86_64.tar.gz
error: 'lyvoxa-Stellar-2.0-linux-x86_64.tar.gz': invalid or corrupted package
```

Pacman expects `.pkg.tar.zst` files with proper PKGINFO metadata, not generic tarballs.

## ✅ Correct Installation Methods

### Method 1: Extract and Use Binaries Directly

**For immediate use without system integration:**

```bash
# Download and verify
curl -LO https://github.com/oxyzenQ/lyvoxa/releases/download/Stellar-2.0/lyvoxa-Stellar-2.0-linux-x86_64.tar.gz
curl -LO https://github.com/oxyzenQ/lyvoxa/releases/download/Stellar-2.0/lyvoxa-Stellar-2.0-linux-x86_64.tar.gz.sha256

# Verify integrity
sha256sum -c lyvoxa-Stellar-2.0-linux-x86_64.tar.gz.sha256

# Extract
tar -xzf lyvoxa-Stellar-2.0-linux-x86_64.tar.gz

# Run directly
./lyvoxa --version

# Optional: Copy to PATH
sudo cp lyvoxa /usr/local/bin/
```

### Method 2: Build Proper Arch Package (Recommended)

**For system integration with pacman:**

```bash
# Clone repository
git clone https://github.com/oxyzenQ/lyvoxa.git
cd lyvoxa

# Build Arch package
make arch-pkg

# Install the package
sudo pacman -U lyvoxa-3.1.0-1-x86_64.pkg.tar.zst       # Source-built (optimized)
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

## 🎯 Recommendations

### For System Integration

```bash
# Build and install source package with native optimizations
make arch-pkg
sudo pacman -U lyvoxa-*.pkg.tar.zst
```

### For Testing/Development

```bash
# Extract and run directly
tar -xzf lyvoxa-Stellar-2.0-linux-x86_64.tar.gz
./lyvoxa
```

## 🔧 Available Commands After Installation

```bash
# Main TUI application
lyvoxa


# Check version
lyvoxa --version

# View help
lyvoxa --help
```

## 🗑️ Uninstallation

```bash
# If installed via pacman
sudo pacman -R lyvoxa      # Source package

# If copied to /usr/local/bin
sudo rm /usr/local/bin/lyvoxa
```

## 🛠️ Building Your Own Package

The repository includes everything needed:

```bash
# Available make targets
make arch-pkg           # Build source package
make arch-pkg-clean     # Clean build artifacts

# Or use the script directly
./build-arch-pkg.sh source   # Build source package
./build-arch-pkg.sh clean    # Clean up
```

## 🔍 Package Contents

The source package installs:

- `/usr/bin/lyvoxa` - Main TUI application
- `/usr/share/doc/lyvoxa/` - Documentation
- `/usr/share/licenses/lyvoxa/` - License files
- Shell completions (if available)
- Man pages (if available)
- Optimized binaries for your specific CPU

---

**Need Help?** Open an issue at: [GitHub Issues](https://github.com/oxyzenQ/lyvoxa/issues)
