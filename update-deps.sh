#!/bin/bash
# =============================================================================
# LYVOXA DEPENDENCY UPDATE SCRIPT
# =============================================================================
# Comprehensive dependency update with major version checks
# Author: rezky_nightky
# Version: Stellar 2.0

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

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

# Install required tools
install_tools() {
    log_info "Installing dependency management tools..."
    
    # Install cargo-edit for dependency management
    if ! command -v cargo-add &> /dev/null; then
        log_info "Installing cargo-edit..."
        cargo install cargo-edit
    fi
    
    # Install cargo-upgrades for major version updates
    if ! command -v cargo-upgrades &> /dev/null; then
        log_info "Installing cargo-upgrades..."
        cargo install cargo-upgrades
    fi
    
    # Install cargo-audit for security checks
    if ! command -v cargo-audit &> /dev/null; then
        log_info "Installing cargo-audit..."
        cargo install cargo-audit
    fi
    
    log_success "Tools installed successfully"
}

# Update dependencies within semver constraints
update_compatible() {
    log_header "🔄 UPDATING COMPATIBLE DEPENDENCIES"
    log_info "Updating dependencies within semver constraints..."
    
    cargo update
    
    log_success "Compatible dependencies updated"
}

# Check for major version upgrades
check_upgrades() {
    log_header "🆙 CHECKING FOR MAJOR VERSION UPGRADES"
    log_info "Checking for available major version upgrades..."
    
    if command -v cargo-upgrades &> /dev/null; then
        log_info "Available major version upgrades:"
        cargo upgrades || log_warning "No major upgrades available or cargo-upgrades not working"
    else
        log_warning "cargo-upgrades not installed, skipping major version check"
    fi
}

# Run security audit
security_audit() {
    log_header "🔒 SECURITY AUDIT"
    log_info "Running security audit..."
    
    cargo audit --color=always || {
        log_warning "Security audit found issues. Review the output above."
        read -p "Continue anyway? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log_error "Security audit failed, aborting"
            exit 1
        fi
    }
    
    log_success "Security audit passed"
}

# Show outdated packages
show_outdated() {
    log_header "📊 DEPENDENCY STATUS"
    log_info "Current dependency status:"
    
    echo ""
    echo "Cargo.toml dependencies:"
    grep -A 20 "^\[dependencies\]" Cargo.toml | grep -E "^[a-zA-Z]" || echo "No dependencies found"
    
    echo ""
    log_info "To manually upgrade a specific dependency:"
    echo "  cargo add <crate>@<version>    # Update to specific version"
    echo "  cargo add <crate>              # Update to latest compatible"
    echo ""
}

# Interactive upgrade mode
interactive_upgrade() {
    log_header "🔧 INTERACTIVE UPGRADE MODE"
    
    if ! command -v cargo-upgrades &> /dev/null; then
        log_error "cargo-upgrades not installed. Install with: cargo install cargo-upgrades"
        return 1
    fi
    
    log_info "Checking for upgradeable dependencies..."
    
    # Get list of upgradeable packages
    UPGRADES=$(cargo upgrades --to-lockfile 2>/dev/null || echo "")
    
    if [ -z "$UPGRADES" ]; then
        log_success "All dependencies are up to date!"
        return 0
    fi
    
    echo "$UPGRADES"
    echo ""
    
    read -p "$(echo -e "${YELLOW}Apply all compatible upgrades? (y/N): ${NC}")" -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        log_info "Applying upgrades..."
        cargo update
        log_success "Upgrades applied"
    else
        log_info "Upgrades skipped"
    fi
}

# Main function
main() {
    log_header "🚀 LYVOXA DEPENDENCY UPDATE TOOL"
    echo ""
    
    # Check if we're in a Rust project
    if [ ! -f "Cargo.toml" ]; then
        log_error "Not in a Rust project directory!"
        exit 1
    fi
    
    case "${1:-compatible}" in
        "install-tools")
            install_tools
            ;;
        "compatible")
            update_compatible
            security_audit
            ;;
        "check")
            check_upgrades
            show_outdated
            ;;
        "interactive")
            update_compatible
            interactive_upgrade
            security_audit
            ;;
        "full")
            install_tools
            update_compatible
            check_upgrades
            security_audit
            show_outdated
            ;;
        "help"|"-h"|"--help")
            echo "Lyvoxa Dependency Update Tool"
            echo ""
            echo "Usage: $0 [COMMAND]"
            echo ""
            echo "Commands:"
            echo "  compatible     Update dependencies within semver constraints (default)"
            echo "  check          Check for major version upgrades available"
            echo "  interactive    Interactive upgrade mode with prompts"
            echo "  install-tools  Install required cargo tools"
            echo "  full          Run complete update cycle"
            echo "  help          Show this help message"
            echo ""
            echo "Examples:"
            echo "  $0                # Update compatible dependencies"
            echo "  $0 interactive    # Interactive upgrade mode"
            echo "  $0 check         # Check for available upgrades"
            ;;
        *)
            log_error "Unknown command: $1"
            log_info "Use '$0 help' for usage information"
            exit 1
            ;;
    esac
}

# Run main function
main "$@"
