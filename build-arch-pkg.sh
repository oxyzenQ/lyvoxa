#!/bin/bash
# =============================================================================
# ARCH LINUX PACKAGE BUILD SCRIPT
# =============================================================================
# Builds proper Arch Linux packages for Lyvoxa
# Author: rezky_nightky
# Version: Stellar 2.0

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_header() {
    echo -e "${CYAN}$1${NC}"
}

# Configuration
PKG_NAME="lyvoxa"
PKG_VERSION="2.0.0"

# Check if we're on Arch Linux
check_arch_linux() {
    if [ ! -f "/etc/arch-release" ]; then
        log_warning "Not running on Arch Linux, but continuing anyway..."
        log_info "Make sure you have makepkg available"
    else
        log_success "Running on Arch Linux"
    fi
}

# Check dependencies
check_dependencies() {
    log_info "Checking build dependencies..."
    
    # Check if makepkg is available
    if ! command -v makepkg &> /dev/null; then
        log_error "makepkg not found! Install base-devel package."
        log_info "Run: sudo pacman -S base-devel"
        exit 1
    fi
    
    # Check if we're in the right directory
    if [ ! -f "PKGBUILD" ]; then
        log_error "PKGBUILD not found in current directory!"
        exit 1
    fi
    
    log_success "Dependencies check passed"
}

# Build source-based package
build_source_package() {
    log_header "🔨 Building Source Package"
    
    log_info "Building from PKGBUILD (source-based)..."
    
    # Clean previous builds
    if [ -d "pkg" ] || [ -d "src" ]; then
        log_info "Cleaning previous build artifacts..."
        rm -rf pkg src
    fi
    
    # Remove existing packages
    rm -f "$PKG_NAME"-*.pkg.tar.*
    
    # Build package
    log_info "Running makepkg..."
    if makepkg -sf --noconfirm; then
        log_success "Source package built successfully!"
        
        # Show resulting package
        RESULT_PKG=$(ls "$PKG_NAME"-*.pkg.tar.* 2>/dev/null | head -1)
        if [ -n "$RESULT_PKG" ]; then
            log_info "Created package: $RESULT_PKG"
            log_info "Package size: $(du -h "$RESULT_PKG" | cut -f1)"
        fi
    else
        log_error "Source package build failed!"
        return 1
    fi
}

# Build binary package
build_binary_package() {
    log_header "📦 Building Binary Package"
    
    if [ ! -f "PKGBUILD-bin" ]; then
        log_warning "PKGBUILD-bin not found, skipping binary package"
        return 0
    fi
    
    log_info "Building from PKGBUILD-bin (pre-built binaries)..."
    
    # Create temporary directory for binary build
    TEMP_DIR=$(mktemp -d)
    cp PKGBUILD-bin "$TEMP_DIR/PKGBUILD"
    
    cd "$TEMP_DIR"
    
    # Clean and build
    log_info "Running makepkg for binary package..."
    if makepkg -sf --noconfirm; then
        log_success "Binary package built successfully!"
        
        # Move result back
        RESULT_PKG=$(ls lyvoxa-bin-*.pkg.tar.* 2>/dev/null | head -1)
        if [ -n "$RESULT_PKG" ]; then
            mv "$RESULT_PKG" "$OLDPWD/"
            log_info "Created package: $RESULT_PKG"
            log_info "Package size: $(du -h "$OLDPWD/$RESULT_PKG" | cut -f1)"
        fi
    else
        log_error "Binary package build failed!"
        cd "$OLDPWD"
        rm -rf "$TEMP_DIR"
        return 1
    fi
    
    cd "$OLDPWD"
    rm -rf "$TEMP_DIR"
}

# Test package installation
test_package() {
    local pkg_file="$1"
    
    if [ ! -f "$pkg_file" ]; then
        log_error "Package file not found: $pkg_file"
        return 1
    fi
    
    log_header "🧪 Testing Package Installation"
    log_info "Testing package: $pkg_file"
    
    # Check package contents
    log_info "Package contents:"
    tar -tf "$pkg_file" | head -20
    
    # Check if package can be queried
    log_info "Package information:"
    pacman -Qip "$pkg_file" 2>/dev/null || {
        log_warning "Could not query package info (this is normal for some systems)"
    }
    
    log_info "Package validation completed"
    echo ""
    log_info "To install this package:"
    echo "  sudo pacman -U $pkg_file"
    echo ""
    log_info "To remove after testing:"
    echo "  sudo pacman -R ${pkg_file%-*-*-*.pkg.tar.*}"
}

# Show installation instructions
show_instructions() {
    log_header "📋 Installation Instructions"
    
    echo ""
    log_info "Available packages:"
    ls -la *.pkg.tar.* 2>/dev/null || log_warning "No packages found"
    
    echo ""
    log_info "Installation options:"
    echo ""
    echo "1. Install source-built package (recommended for performance):"
    if ls lyvoxa-[0-9]*.pkg.tar.* >/dev/null 2>&1; then
        SOURCE_PKG=$(ls lyvoxa-[0-9]*.pkg.tar.* | head -1)
        echo "   sudo pacman -U $SOURCE_PKG"
    else
        echo "   (source package not found)"
    fi
    
    echo ""
    echo "2. Install binary package (faster installation):"
    if ls lyvoxa-bin-*.pkg.tar.* >/dev/null 2>&1; then
        BIN_PKG=$(ls lyvoxa-bin-*.pkg.tar.* | head -1)
        echo "   sudo pacman -U $BIN_PKG"
    else
        echo "   (binary package not found)"
    fi
    
    echo ""
    log_info "After installation, you can run:"
    echo "   lyvoxa          # Main TUI application"
    echo "   lyvoxa-simple   # Lightweight version"
    
    echo ""
    log_info "To uninstall:"
    echo "   sudo pacman -R lyvoxa      # or lyvoxa-bin"
}

# Main function
main() {
    log_header "🏗️ LYVOXA ARCH LINUX PACKAGE BUILDER"
    echo ""
    
    case "${1:-both}" in
        "source")
            check_arch_linux
            check_dependencies
            build_source_package
            if ls lyvoxa-[0-9]*.pkg.tar.* >/dev/null 2>&1; then
                test_package "$(ls lyvoxa-[0-9]*.pkg.tar.* | head -1)"
            fi
            ;;
        "binary")
            check_arch_linux
            check_dependencies
            build_binary_package
            if ls lyvoxa-bin-*.pkg.tar.* >/dev/null 2>&1; then
                test_package "$(ls lyvoxa-bin-*.pkg.tar.* | head -1)"
            fi
            ;;
        "both")
            check_arch_linux
            check_dependencies
            
            log_info "Building both source and binary packages..."
            echo ""
            
            build_source_package || log_error "Source build failed"
            echo ""
            build_binary_package || log_error "Binary build failed"
            echo ""
            
            # Test first available package
            if ls *.pkg.tar.* >/dev/null 2>&1; then
                test_package "$(ls *.pkg.tar.* | head -1)"
            fi
            ;;
        "clean")
            log_info "Cleaning build artifacts..."
            rm -rf pkg src *.pkg.tar.*
            log_success "Clean completed"
            exit 0
            ;;
        "help"|"-h"|"--help")
            echo "Lyvoxa Arch Linux Package Builder"
            echo ""
            echo "Usage: $0 [COMMAND]"
            echo ""
            echo "Commands:"
            echo "  source    Build source-based package only"
            echo "  binary    Build binary package only"
            echo "  both      Build both packages (default)"
            echo "  clean     Clean build artifacts"
            echo "  help      Show this help"
            echo ""
            echo "Examples:"
            echo "  $0              # Build both packages"
            echo "  $0 source       # Build from source only"
            echo "  $0 binary       # Build binary package only"
            exit 0
            ;;
        *)
            log_error "Unknown command: $1"
            log_info "Use '$0 help' for usage information"
            exit 1
            ;;
    esac
    
    show_instructions
    
    log_success "Package build completed! 🎉"
}

# Run main with all arguments
main "$@"
