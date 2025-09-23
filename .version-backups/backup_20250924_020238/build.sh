#!/bin/bash
# =============================================================================
# LYVOXA BUILD AUTOMATION SCRIPT
# =============================================================================
# Optimized build script with CPU core limits and caching for Arch Linux
# Author: rezky_nightky
# Version: Stellar 1.5

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
MAX_JOBS=3
TARGET="x86_64-unknown-linux-gnu"
PROJECT_NAME="lyvoxa"

# Override system MAKEFLAGS for heat control
export MAKEFLAGS="-j${MAX_JOBS}"

# Functions
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

check_dependencies() {
    log_info "Checking build dependencies..."
    
    # Check if rustup is installed
    if ! command -v rustup &> /dev/null; then
        log_error "rustup is not installed. Please install it first."
        exit 1
    fi
    
    # Check if sccache is available
    if command -v sccache &> /dev/null; then
        log_success "sccache found - build caching enabled"
        export RUSTC_WRAPPER=sccache
    else
        log_warning "sccache not found - consider installing for faster builds: 'cargo install sccache'"
    fi
    
    # Check if mold linker is available
    if command -v mold &> /dev/null; then
        log_success "mold linker found - faster linking enabled"
    else
        log_warning "mold linker not found - consider installing for faster linking: 'paru -S mold'"
    fi
}

show_system_info() {
    log_info "System Information:"
    echo "  OS: $(uname -s) $(uname -m)"
    echo "  CPU Cores: $(nproc)"
    echo "  Build Jobs: ${MAX_JOBS} (limited for heat control)"
    echo "  Target: ${TARGET}"
    echo "  Rust Version: $(rustc --version)"
    echo "  Cargo Version: $(cargo --version)"
}

build_debug() {
    log_info "Building debug version with ${MAX_JOBS} CPU cores..."
    log_info "Command: cargo build --jobs ${MAX_JOBS} --target ${TARGET}"
    
    time cargo build --jobs ${MAX_JOBS} --target ${TARGET}
    
    if [ $? -eq 0 ]; then
        log_success "Debug build completed successfully!"
        log_info "Binary location: target/${TARGET}/debug/${PROJECT_NAME}"
    else
        log_error "Debug build failed!"
        exit 1
    fi
}

build_release() {
    log_info "Building release version with ${MAX_JOBS} CPU cores..."
    log_info "Command: cargo build --release --jobs ${MAX_JOBS} --target ${TARGET}"
    
    time cargo build --release --jobs ${MAX_JOBS} --target ${TARGET}
    
    if [ $? -eq 0 ]; then
        log_success "Release build completed successfully!"
        log_info "Binary location: target/${TARGET}/release/${PROJECT_NAME}"
        
        # Show binary size
        local binary_path="target/${TARGET}/release/${PROJECT_NAME}"
        if [ -f "$binary_path" ]; then
            local size=$(du -h "$binary_path" | cut -f1)
            log_info "Binary size: ${size}"
        fi
    else
        log_error "Release build failed!"
        exit 1
    fi
}

build_release_with_debug() {
    log_info "Building release with debug info for profiling..."
    log_info "Command: cargo build --profile release-with-debug --jobs ${MAX_JOBS} --target ${TARGET}"
    
    time cargo build --profile release-with-debug --jobs ${MAX_JOBS} --target ${TARGET}
    
    if [ $? -eq 0 ]; then
        log_success "Release with debug build completed successfully!"
        log_info "Binary location: target/${TARGET}/release-with-debug/${PROJECT_NAME}"
    else
        log_error "Release with debug build failed!"
        exit 1
    fi
}

run_tests() {
    log_info "Running tests with ${MAX_JOBS} CPU cores..."
    log_info "Command: cargo test --jobs ${MAX_JOBS} --target ${TARGET}"
    
    cargo test --jobs ${MAX_JOBS} --target ${TARGET}
    
    if [ $? -eq 0 ]; then
        log_success "All tests passed!"
    else
        log_error "Tests failed!"
        exit 1
    fi
}

run_clippy() {
    log_info "Running Clippy linter..."
    cargo clippy --target ${TARGET} -- -D warnings
    
    if [ $? -eq 0 ]; then
        log_success "Clippy checks passed!"
    else
        log_error "Clippy found issues!"
        exit 1
    fi
}

run_fmt_check() {
    log_info "Checking code formatting..."
    cargo fmt --check
    
    if [ $? -eq 0 ]; then
        log_success "Code formatting is correct!"
    else
        log_error "Code formatting issues found! Run 'cargo fmt' to fix."
        exit 1
    fi
}

clean_build() {
    log_info "Cleaning build artifacts..."
    cargo clean
    log_success "Build artifacts cleaned!"
}

show_sccache_stats() {
    if command -v sccache &> /dev/null; then
        log_info "sccache statistics:"
        sccache --show-stats
    fi
}

show_help() {
    echo "Lyvoxa Build Script - Stellar 1.5"
    echo ""
    echo "Usage: $0 [COMMAND]"
    echo ""
    echo "Commands:"
    echo "  debug          Build debug version (default)"
    echo "  release        Build optimized release version"
    echo "  release-debug  Build release with debug info"
    echo "  test           Run all tests"
    echo "  check          Run quick checks (clippy + fmt)"
    echo "  clean          Clean build artifacts"
    echo "  all            Build debug + release + run tests"
    echo "  stats          Show sccache statistics"
    echo "  help           Show this help message"
    echo ""
    echo "Environment Variables:"
    echo "  LYVOXA_JOBS    Override CPU core limit (default: 3)"
    echo ""
    echo "Examples:"
    echo "  $0 release     # Build release version"
    echo "  $0 all         # Full build and test cycle"
    echo "  LYVOXA_JOBS=2 $0 release  # Build with 2 cores"
}

# Main execution
main() {
    # Override MAX_JOBS if environment variable is set
    if [ -n "${LYVOXA_JOBS:-}" ]; then
        MAX_JOBS="${LYVOXA_JOBS}"
        log_info "CPU core limit overridden to: ${MAX_JOBS}"
    fi
    
    # Ensure we're in the project directory
    if [ ! -f "Cargo.toml" ]; then
        log_error "Not in a Rust project directory!"
        exit 1
    fi
    
    case "${1:-debug}" in
        "debug")
            check_dependencies
            show_system_info
            build_debug
            ;;
        "release")
            check_dependencies
            show_system_info
            build_release
            ;;
        "release-debug")
            check_dependencies
            show_system_info
            build_release_with_debug
            ;;
        "test")
            check_dependencies
            run_tests
            ;;
        "check")
            run_clippy
            run_fmt_check
            ;;
        "clean")
            clean_build
            ;;
        "all")
            check_dependencies
            show_system_info
            run_fmt_check
            run_clippy
            build_debug
            build_release
            run_tests
            show_sccache_stats
            ;;
        "stats")
            show_sccache_stats
            ;;
        "help"|"-h"|"--help")
            show_help
            ;;
        *)
            log_error "Unknown command: $1"
            show_help
            exit 1
            ;;
    esac
}

# Execute main function with all arguments
main "$@"
