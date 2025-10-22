#!/bin/bash
# =============================================================================
# LYVOXA UNIFIED MAINTENANCE TOOL
# =============================================================================
# All-in-one maintenance script for Lyvoxa project
# Combines: setup-git-hooks, update-deps, update-version, version-manager
#
# Usage:
#   ./lyvoxa-maintain.sh setup             # Setup git hooks
#   ./lyvoxa-maintain.sh update-deps       # Update dependencies
#   ./lyvoxa-maintain.sh update-version    # Update version
#   ./lyvoxa-maintain.sh version [show]    # Show current version
#   ./lyvoxa-maintain.sh help              # Show help
#
# Author: rezky_nightky
# Version: Stellar 3.0
# =============================================================================

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# Configuration
VERSION_FILE="version.toml"
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# UTILITY FUNCTIONS
# =============================================================================

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_header() { echo -e "${BOLD}${CYAN}$1${NC}"; }

print_header() {
    echo ""
    echo -e "${BOLD}${BLUE}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${BOLD}${CYAN}  🚀 LYVOXA MAINTENANCE TOOL - Stellar 3.0${NC}"
    echo -e "${BOLD}${BLUE}═══════════════════════════════════════════════════════════════${NC}"
    echo ""
}

require_command() {
    if ! command -v "$1" &> /dev/null; then
        log_error "$1 is required but not installed"
        exit 1
    fi
}

# =============================================================================
# GIT HOOKS SETUP
# =============================================================================

setup_git_hooks() {
    log_header "Setting up Git Hooks"
    
    local hooks_dir=".git/hooks"
    
    if [ ! -d ".git" ]; then
        log_error "Not a git repository"
        return 1
    fi
    
    if [ ! -f "pre-commit.sh" ]; then
        log_error "pre-commit.sh not found"
        return 1
    fi
    
    # Create pre-commit hook
    log_info "Creating pre-commit hook..."
    cat > "${hooks_dir}/pre-commit" << 'EOF'
#!/bin/bash
# Lyvoxa pre-commit hook
exec ./pre-commit.sh
EOF
    
    chmod +x "${hooks_dir}/pre-commit"
    log_success "Pre-commit hook installed"
    
    # Create commit-msg hook
    log_info "Creating commit-msg hook..."
    cat > "${hooks_dir}/commit-msg" << 'EOF'
#!/bin/bash
# Conventional Commits validation
commit_msg=$(cat "$1")

# Pattern for conventional commits
pattern="^(feat|fix|docs|style|refactor|perf|test|build|ci|chore|revert)(\(.+\))?: .{1,100}"

if ! echo "$commit_msg" | grep -qE "$pattern"; then
    echo "ERROR: Commit message must follow Conventional Commits format"
    echo "Format: type(scope): description"
    echo "Types: feat, fix, docs, style, refactor, perf, test, build, ci, chore, revert"
    exit 1
fi
EOF
    
    chmod +x "${hooks_dir}/commit-msg"
    log_success "Commit-msg hook installed"
    
    # Test hooks
    log_info "Testing hooks..."
    if [ -x "${hooks_dir}/pre-commit" ] && [ -x "${hooks_dir}/commit-msg" ]; then
        log_success "All hooks are executable and ready"
    else
        log_warning "Some hooks may not be executable"
    fi
    
    echo ""
    log_success "Git hooks setup complete!"
}

# =============================================================================
# DEPENDENCY UPDATE
# =============================================================================

update_dependencies() {
    log_header "Updating Dependencies"
    
    require_command cargo
    
    # Update Cargo dependencies
    log_info "Updating Cargo dependencies..."
    if cargo update; then
        log_success "Cargo dependencies updated"
    else
        log_error "Failed to update Cargo dependencies"
        return 1
    fi
    
    # Check for outdated packages
    if command -v cargo-outdated &> /dev/null; then
        log_info "Checking for outdated packages..."
        cargo outdated --depth 1
    else
        log_info "Install cargo-outdated for detailed update info: cargo install cargo-outdated"
    fi
    
    # Run audit
    if command -v cargo-audit &> /dev/null; then
        log_info "Running security audit..."
        if cargo audit; then
            log_success "No security vulnerabilities found"
        else
            log_warning "Security audit found issues - check output above"
        fi
    else
        log_info "Install cargo-audit for security checks: cargo install cargo-audit"
    fi
    
    echo ""
    log_success "Dependency update complete!"
}

# =============================================================================
# VERSION MANAGEMENT
# =============================================================================

read_version_toml() {
    if [ ! -f "$VERSION_FILE" ]; then
        log_error "version.toml not found"
        return 1
    fi
    
    # Parse TOML (simple extraction)
    CURRENT_VERSION=$(grep '^semantic = ' "$VERSION_FILE" | sed 's/semantic = "\(.*\)"/\1/')
    RELEASE_NAME=$(grep '^release_name = ' "$VERSION_FILE" | sed 's/release_name = "\(.*\)"/\1/')
    RELEASE_NUMBER=$(grep '^release_number = ' "$VERSION_FILE" | sed 's/release_number = "\(.*\)"/\1/')
}

show_version() {
    read_version_toml
    
    echo ""
    log_header "Current Version Information"
    echo ""
    echo -e "  ${BOLD}Version:${NC}        ${CYAN}${CURRENT_VERSION}${NC}"
    echo -e "  ${BOLD}Release Name:${NC}   ${CYAN}${RELEASE_NAME}${NC}"
    echo -e "  ${BOLD}Release Number:${NC} ${CYAN}${RELEASE_NUMBER}${NC}"
    echo -e "  ${BOLD}Release Tag:${NC}    ${CYAN}${RELEASE_NAME,,}-${RELEASE_NUMBER}${NC}"
    echo ""
}

update_version() {
    log_header "Version Update Wizard"
    
    read_version_toml
    
    echo ""
    echo "Current version: ${CYAN}${CURRENT_VERSION}${NC} (${RELEASE_NAME} ${RELEASE_NUMBER})"
    echo ""
    
    # Get new version
    read -p "Enter new version (e.g., 3.1.0): " NEW_VERSION
    if [ -z "$NEW_VERSION" ]; then
        log_error "Version cannot be empty"
        return 1
    fi
    
    # Validate semantic version
    if ! echo "$NEW_VERSION" | grep -qE '^[0-9]+\.[0-9]+\.[0-9]+$'; then
        log_error "Invalid version format. Use semantic versioning (e.g., 3.1.0)"
        return 1
    fi
    
    read -p "Enter release name (e.g., Stellar): " NEW_RELEASE_NAME
    NEW_RELEASE_NAME=${NEW_RELEASE_NAME:-$RELEASE_NAME}
    
    read -p "Enter release number (e.g., 3.1): " NEW_RELEASE_NUMBER
    NEW_RELEASE_NUMBER=${NEW_RELEASE_NUMBER:-$(echo "$NEW_VERSION" | cut -d. -f1-2)}
    
    # Confirm
    echo ""
    echo "Will update:"
    echo "  Version: ${CURRENT_VERSION} → ${CYAN}${NEW_VERSION}${NC}"
    echo "  Release: ${RELEASE_NAME} ${RELEASE_NUMBER} → ${CYAN}${NEW_RELEASE_NAME} ${NEW_RELEASE_NUMBER}${NC}"
    echo ""
    read -p "Continue? (y/N): " -n 1 -r
    echo
    
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_warning "Version update cancelled"
        return 0
    fi
    
    # Update version.toml
    log_info "Updating version.toml..."
    sed -i "s/semantic = \".*\"/semantic = \"$NEW_VERSION\"/" "$VERSION_FILE"
    sed -i "s/release_name = \".*\"/release_name = \"$NEW_RELEASE_NAME\"/" "$VERSION_FILE"
    sed -i "s/release_number = \".*\"/release_number = \"$NEW_RELEASE_NUMBER\"/" "$VERSION_FILE"
    sed -i "s/release_tag = \".*\"/release_tag = \"${NEW_RELEASE_NAME,,}-$NEW_RELEASE_NUMBER\"/" "$VERSION_FILE"
    
    # Update Cargo.toml
    log_info "Updating Cargo.toml..."
    sed -i "s/^version = \".*\"/version = \"$NEW_VERSION\"/" Cargo.toml
    
    # Update README.md
    if [ -f "README.md" ]; then
        log_info "Updating README.md..."
        sed -i "s/Current Version.*: .*/Current Version**: $NEW_RELEASE_NAME $NEW_RELEASE_NUMBER (v$NEW_VERSION)/" README.md
    fi
    
    # Update workflows
    for workflow in .github/workflows/*.yml; do
        if [ -f "$workflow" ]; then
            sed -i "s/Version: ${RELEASE_NAME} ${RELEASE_NUMBER}/Version: $NEW_RELEASE_NAME $NEW_RELEASE_NUMBER/g" "$workflow"
        fi
    done
    
    # Update shell scripts
    for script in *.sh; do
        if [ -f "$script" ]; then
            sed -i "s/Version: ${RELEASE_NAME} ${RELEASE_NUMBER}/Version: $NEW_RELEASE_NAME $NEW_RELEASE_NUMBER/g" "$script"
        fi
    done
    
    log_success "Version updated to $NEW_VERSION ($NEW_RELEASE_NAME $NEW_RELEASE_NUMBER)"
    
    # Show what changed
    log_info "Files modified:"
    git status --short | grep -E "(version.toml|Cargo.toml|README.md|.yml|.sh)" || true
    
    echo ""
    log_warning "Don't forget to:"
    echo "  1. Update CHANGELOG.md with release notes"
    echo "  2. Run: cargo build --release"
    echo "  3. Test the build"
    echo "  4. Commit changes: git add -A && git commit -m 'chore(release): bump to $NEW_VERSION'"
}

# =============================================================================
# MAIN MENU
# =============================================================================

show_help() {
    print_header
    echo "Usage: $0 <command>"
    echo ""
    echo "Commands:"
    echo "  ${CYAN}setup${NC}              Setup git hooks for pre-commit checks"
    echo "  ${CYAN}update-deps${NC}        Update and audit Cargo dependencies"
    echo "  ${CYAN}update-version${NC}     Interactive version update wizard"
    echo "  ${CYAN}version${NC}            Show current version information"
    echo "  ${CYAN}all${NC}                Run setup + update-deps"
    echo "  ${CYAN}help${NC}               Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 setup           # First-time setup"
    echo "  $0 update-deps     # Update dependencies"
    echo "  $0 version         # Check current version"
    echo "  $0 update-version  # Update version across project"
    echo ""
}

run_all() {
    print_header
    setup_git_hooks
    echo ""
    update_dependencies
    echo ""
    log_success "All maintenance tasks complete!"
}

# =============================================================================
# MAIN
# =============================================================================

main() {
    cd "$PROJECT_ROOT"
    
    case "${1:-help}" in
        setup)
            print_header
            setup_git_hooks
            ;;
        update-deps|deps)
            print_header
            update_dependencies
            ;;
        update-version)
            print_header
            update_version
            ;;
        version|show)
            show_version
            ;;
        all)
            run_all
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            log_error "Unknown command: $1"
            echo ""
            show_help
            exit 1
            ;;
    esac
}

main "$@"
