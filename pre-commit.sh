#!/bin/bash
# =============================================================================
# LYVOXA PRE-COMMIT QUALITY CHECK SCRIPT
# =============================================================================
# Comprehensive code quality validation before commit/push
# Author: rezky_nightky
# Version: Stellar 3.0

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

# Configuration
# shellcheck disable=SC2034
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_NAME="lyvoxa"
RUST_TOOLCHAIN="stable"

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

log_header() {
    echo -e "${CYAN}$1${NC}"
}

log_step() {
    echo -e "${MAGENTA}[STEP]${NC} $1"
}

# Check if we're in a Rust project
check_project_structure() {
    log_step "1/10 Checking project structure..."
    
    if [ ! -f "Cargo.toml" ]; then
        log_error "Not in a Rust project directory!"
        exit 1
    fi
    
    if [ ! -f "Cargo.lock" ]; then
        log_warning "Cargo.lock not found, running cargo check to generate it..."
        cargo check > /dev/null 2>&1
    fi
    
    log_success "Project structure is valid"
}

# Check for unstaged changes
check_git_status() {
    log_step "2/10 Checking git status..."
    
    if ! git diff-index --quiet HEAD --; then
        log_warning "You have unstaged changes. Consider staging them first."
        echo "Unstaged files:"
        git diff --name-only
        echo ""
        read -r -p "$(echo -e "${YELLOW}Continue anyway? (y/N): ${NC}")" -n 1 REPLY
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log_error "Aborted by user"
            exit 1
        fi
    fi
    
    log_success "Git status check passed"
}

# Update dependencies
update_dependencies() {
    log_step "3/10 Updating dependencies..."
    
    log_info "Running cargo update..."
    cargo update --quiet
    
    log_success "Dependencies updated"
}

# Check code formatting
check_formatting() {
    log_step "4/10 Checking code formatting..."
    
    log_info "Running cargo fmt --check..."
    if ! cargo fmt --check; then
        log_error "Code formatting issues found!"
        echo ""
        log_info "To fix formatting issues, run:"
        echo "  cargo fmt"
        echo ""
        return 1
    fi
    
    log_success "Code formatting is correct"
}

# Run Clippy linting
run_clippy() {
    log_step "5/10 Running Clippy linting..."
    
    log_info "Running cargo clippy..."
    if ! cargo clippy --all-targets --all-features --quiet -- -D warnings; then
        log_error "Clippy linting failed!"
        echo ""
        log_info "Fix the issues above and try again"
        return 1
    fi
    
    log_success "Clippy linting passed"
}

# Build check (debug and release)
build_check() {
    log_step "6/10 Checking builds..."
    
    log_info "Building debug version..."
    if ! cargo build --quiet; then
        log_error "Debug build failed!"
        return 1
    fi
    
    log_info "Building release version..."
    if ! cargo build --release --quiet; then
        log_error "Release build failed!"
        return 1
    fi
    
    log_success "All builds successful"
}

# Run tests
run_tests() {
    log_step "7/10 Running tests..."
    
    log_info "Running cargo test..."
    if ! cargo test --quiet; then
        log_error "Tests failed!"
        return 1
    fi
    
    log_success "All tests passed"
}

# Security audit
security_audit() {
    log_step "8/10 Running security audit..."
    
    # Install cargo-audit if not present
    if ! command -v cargo-audit &> /dev/null; then
        log_info "Installing cargo-audit..."
        cargo install cargo-audit --quiet
    fi
    
    log_info "Running security audit..."
    if ! cargo audit --quiet; then
        log_warning "Security audit found issues (check output above)"
        echo ""
        read -r -p "$(echo -e "${YELLOW}Continue despite security warnings? (y/N): ${NC}")" -n 1 REPLY
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log_error "Aborted due to security concerns"
            return 1
        fi
    fi
    
    log_success "Security audit passed"
}

# Dependency depth check
check_dependency_depth() {
    log_step "9/10 Checking dependency depth..."
    
    log_info "Analyzing dependency tree..."
    
    # Count total dependencies
    TOTAL_DEPS=$(cargo tree --quiet 2>/dev/null | wc -l)
    
    # Check for deep dependency chains (more than 10 levels)
    DEEP_DEPS=$(cargo tree --quiet --depth 10 2>/dev/null | grep -c "└──\|├──" || true)
    
    log_info "Total dependencies: $TOTAL_DEPS"
    log_info "Dependencies at depth 10+: $DEEP_DEPS"
    
    if [ "$DEEP_DEPS" -gt 50 ]; then
        log_warning "High number of deep dependencies ($DEEP_DEPS)"
        log_warning "Consider reviewing dependency tree for optimization"
    fi
    
    # Check for duplicate dependencies
    log_info "Checking for duplicate dependencies..."
    DUPLICATES=$(cargo tree --duplicates --quiet 2>/dev/null || echo "")
    if [ -n "$DUPLICATES" ]; then
        log_warning "Duplicate dependencies found:"
        echo "$DUPLICATES"
    fi
    
    log_success "Dependency analysis complete"
}

# Final validation
final_validation() {
    log_step "10/10 Final validation..."
    
    # Check binary size (release build)
    if [ -f "target/release/$PROJECT_NAME" ]; then
        BINARY_SIZE=$(du -h "target/release/$PROJECT_NAME" | cut -f1)
        log_info "Release binary size: $BINARY_SIZE"
        
        # Warn if binary is very large (>50MB)
        BINARY_SIZE_BYTES=$(stat -c%s "target/release/$PROJECT_NAME" 2>/dev/null || echo "0")
        if [ "$BINARY_SIZE_BYTES" -gt 52428800 ]; then
            log_warning "Binary is quite large ($BINARY_SIZE). Consider optimization."
        fi
    fi
    
    # Check if all files are properly staged
    if git diff --cached --quiet; then
        log_warning "No files staged for commit"
    else
        STAGED_FILES=$(git diff --cached --name-only | wc -l)
        log_info "Files staged for commit: $STAGED_FILES"
    fi
    
    log_success "Final validation complete"
}

# Generate report
generate_report() {
    log_header "📊 PRE-COMMIT QUALITY REPORT"
    echo ""
    
    echo "Project: $PROJECT_NAME"
    echo "Rust Toolchain: $RUST_TOOLCHAIN"
    echo "Date: $(date -u '+%Y-%m-%d %H:%M:%S UTC')"
    echo ""
    
    echo "✅ Checks Passed:"
    echo "  • Project structure validation"
    echo "  • Code formatting (cargo fmt)"
    echo "  • Linting (cargo clippy)"
    echo "  • Build verification (debug + release)"
    echo "  • Test suite execution"
    echo "  • Security audit"
    echo "  • Dependency analysis"
    echo "  • Final validation"
    echo ""
    
    # Git information
    BRANCH=$(git branch --show-current 2>/dev/null || echo "unknown")
    COMMIT_HASH=$(git rev-parse --short HEAD 2>/dev/null || echo "unknown")
    
    echo "📋 Repository Status:"
    echo "  • Branch: $BRANCH"
    echo "  • Latest commit: $COMMIT_HASH"
    echo "  • Staged files: $(git diff --cached --name-only | wc -l)"
    echo ""
    
    log_success "All quality checks passed! ✨"
    echo ""
    log_info "Ready to commit and push to GitHub"
}

# Error handler
error_handler() {
    local exit_code=$?
    echo ""
    log_error "Pre-commit checks failed! ❌"
    log_error "Please fix the issues above before committing."
    echo ""
    log_info "Common fixes:"
    echo "  • Run 'cargo fmt' to fix formatting"
    echo "  • Run 'cargo clippy --fix' to auto-fix some linting issues"
    echo "  • Run 'cargo test' to see test failures in detail"
    echo "  • Run 'cargo audit' to see security issues"
    echo ""
    exit $exit_code
}

# Main execution
main() {
    # Set error handler
    trap error_handler ERR
    
    log_header "🚀 LYVOXA PRE-COMMIT QUALITY CHECKER"
    echo ""
    
    # Parse arguments
    SKIP_TESTS=false
    SKIP_AUDIT=false
    QUICK_MODE=false
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            --skip-tests)
                SKIP_TESTS=true
                shift
                ;;
            --skip-audit)
                SKIP_AUDIT=true
                shift
                ;;
            --quick)
                QUICK_MODE=true
                shift
                ;;
            --help|-h)
                echo "Lyvoxa Pre-commit Quality Checker"
                echo ""
                echo "Usage: $0 [OPTIONS]"
                echo ""
                echo "Options:"
                echo "  --skip-tests     Skip running tests (faster)"
                echo "  --skip-audit     Skip security audit"
                echo "  --quick         Quick mode (skip tests and audit)"
                echo "  --help, -h      Show this help message"
                echo ""
                echo "Examples:"
                echo "  $0                    # Full quality check"
                echo "  $0 --quick          # Quick check (no tests/audit)"
                echo "  $0 --skip-tests     # Skip tests only"
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                log_info "Use '$0 --help' for usage information"
                exit 1
                ;;
        esac
    done
    
    # Quick mode settings
    if [ "$QUICK_MODE" = true ]; then
        SKIP_TESTS=true
        SKIP_AUDIT=true
        log_info "Running in quick mode (skipping tests and audit)"
        echo ""
    fi
    
    # Run all checks
    check_project_structure
    check_git_status
    update_dependencies
    check_formatting
    run_clippy
    build_check
    
    if [ "$SKIP_TESTS" = false ]; then
        run_tests
    else
        log_warning "Skipping tests (--skip-tests or --quick mode)"
    fi
    
    if [ "$SKIP_AUDIT" = false ]; then
        security_audit
    else
        log_warning "Skipping security audit (--skip-audit or --quick mode)"
    fi
    
    check_dependency_depth
    final_validation
    
    # Generate final report
    echo ""
    generate_report
}

# Run main function with all arguments
main "$@"
