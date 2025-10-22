#!/bin/bash
# =============================================================================
# Dependabot Configuration Verification Script
# =============================================================================
# This script checks if all requirements for Dependabot auto-merge are met
# and provides actionable feedback for any missing configurations.
#
# Usage: ./check-dependabot-config.sh
# =============================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Counters
PASSED=0
FAILED=0
WARNINGS=0

# Print header
print_header() {
    echo -e "${BLUE}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║        Dependabot Configuration Verification                   ║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

# Print section
print_section() {
    echo -e "${BLUE}▶ $1${NC}"
    echo "─────────────────────────────────────────────────────"
}

# Print success
print_success() {
    echo -e "${GREEN}✓${NC} $1"
    ((PASSED++))
}

# Print error
print_error() {
    echo -e "${RED}✗${NC} $1"
    ((FAILED++))
}

# Print warning
print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
    ((WARNINGS++))
}

# Print info
print_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

# Check if file exists
check_file() {
    local file=$1
    local description=$2
    
    if [ -f "$file" ]; then
        print_success "$description exists"
        return 0
    else
        print_error "$description not found: $file"
        return 1
    fi
}

# Check YAML syntax
check_yaml_syntax() {
    local file=$1
    
    if command -v yamllint >/dev/null 2>&1; then
        if yamllint -d relaxed "$file" >/dev/null 2>&1; then
            print_success "YAML syntax is valid"
            return 0
        else
            print_error "YAML syntax is invalid"
            echo "  Run: yamllint $file"
            return 1
        fi
    else
        print_warning "yamllint not installed, skipping syntax check"
        echo "  Install with: pip install yamllint"
        return 0
    fi
}

# Check GitHub CLI
check_gh_cli() {
    if command -v gh >/dev/null 2>&1; then
        print_success "GitHub CLI is installed"
        
        if gh auth status >/dev/null 2>&1; then
            print_success "GitHub CLI is authenticated"
            return 0
        else
            print_warning "GitHub CLI is not authenticated"
            echo "  Run: gh auth login"
            return 1
        fi
    else
        print_warning "GitHub CLI is not installed"
        echo "  Install from: https://cli.github.com/"
        return 1
    fi
}

# Check repository settings (requires gh CLI)
check_repo_settings() {
    if ! command -v gh >/dev/null 2>&1; then
        print_warning "Cannot check repository settings (gh CLI not available)"
        return 1
    fi
    
    if ! gh auth status >/dev/null 2>&1; then
        print_warning "Cannot check repository settings (gh CLI not authenticated)"
        return 1
    fi
    
    # Get repository info
    local repo_info
    repo_info=$(gh repo view --json allowAutoMerge,hasVulnerabilityAlertsEnabled 2>/dev/null || echo "")
    
    if [ -z "$repo_info" ]; then
        print_warning "Cannot retrieve repository settings"
        return 1
    fi
    
    # Check auto-merge
    if echo "$repo_info" | grep -q '"allowAutoMerge":true'; then
        print_success "Auto-merge is enabled"
    else
        print_error "Auto-merge is not enabled"
        echo "  Enable at: Settings → General → Pull Requests → Allow auto-merge"
    fi
    
    # Check vulnerability alerts
    if echo "$repo_info" | grep -q '"hasVulnerabilityAlertsEnabled":true'; then
        print_success "Vulnerability alerts are enabled"
    else
        print_warning "Vulnerability alerts are not enabled"
        echo "  Enable at: Settings → Code security and analysis → Dependabot alerts"
    fi
}

# Check workflow permissions
check_workflow_permissions() {
    if ! command -v gh >/dev/null 2>&1; then
        print_warning "Cannot check workflow permissions (gh CLI not available)"
        return 1
    fi
    
    print_info "Check workflow permissions manually:"
    echo "  Settings → Actions → General → Workflow permissions"
    echo "  Ensure: Read and write permissions is enabled"
    echo "  Ensure: Allow GitHub Actions to create and approve pull requests is enabled"
}

# Check Cargo.toml exists
check_cargo_files() {
    if [ -f "Cargo.toml" ]; then
        print_success "Cargo.toml found"
    else
        print_warning "Cargo.toml not found (not a Rust project?)"
    fi
    
    if [ -f "Cargo.lock" ]; then
        print_success "Cargo.lock found"
    else
        print_warning "Cargo.lock not found"
        echo "  Run: cargo build"
    fi
}

# Check CI workflow
check_ci_workflow() {
    local ci_file=".github/workflows/ci.yml"
    
    if [ -f "$ci_file" ]; then
        print_success "CI workflow found"
        
        # Check if CI runs on pull_request
        if grep -q "pull_request:" "$ci_file"; then
            print_success "CI runs on pull requests"
        else
            print_warning "CI may not run on pull requests"
            echo "  Ensure 'pull_request:' trigger is configured"
        fi
    else
        print_error "CI workflow not found: $ci_file"
        echo "  Create a CI workflow to enable automatic checks"
    fi
}

# Check dependabot.yml configuration
check_dependabot_config() {
    local config_file=".github/dependabot.yml"
    
    if [ ! -f "$config_file" ]; then
        return 1
    fi
    
    # Check for cargo ecosystem
    if grep -q 'package-ecosystem: "cargo"' "$config_file"; then
        print_success "Cargo ecosystem is configured"
    else
        print_warning "Cargo ecosystem not found in dependabot.yml"
    fi
    
    # Check for github-actions ecosystem
    if grep -q 'package-ecosystem: "github-actions"' "$config_file"; then
        print_success "GitHub Actions ecosystem is configured"
    else
        print_warning "GitHub Actions ecosystem not found in dependabot.yml"
    fi
    
    # Check for auto-merge label
    if grep -q 'auto-merge' "$config_file"; then
        print_success "Auto-merge label is configured"
    else
        print_warning "Auto-merge label not found in dependabot.yml"
    fi
}

# Main execution
main() {
    print_header
    
    # Change to repository root
    cd "$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
    
    # Check configuration files
    print_section "Configuration Files"
    check_file ".github/dependabot.yml" "Dependabot configuration"
    check_file ".github/workflows/dependabot-auto-merge.yml" "Auto-merge workflow"
    check_file ".github/DEPENDABOT_SETUP.md" "Setup documentation"
    echo ""
    
    # Check YAML syntax
    print_section "YAML Syntax"
    if [ -f ".github/dependabot.yml" ]; then
        check_yaml_syntax ".github/dependabot.yml"
    fi
    if [ -f ".github/workflows/dependabot-auto-merge.yml" ]; then
        check_yaml_syntax ".github/workflows/dependabot-auto-merge.yml"
    fi
    echo ""
    
    # Check Dependabot configuration
    print_section "Dependabot Configuration"
    check_dependabot_config
    echo ""
    
    # Check project files
    print_section "Project Files"
    check_cargo_files
    echo ""
    
    # Check CI workflow
    print_section "CI/CD Workflow"
    check_ci_workflow
    echo ""
    
    # Check GitHub CLI
    print_section "GitHub CLI"
    check_gh_cli
    echo ""
    
    # Check repository settings
    print_section "Repository Settings"
    check_repo_settings
    echo ""
    
    # Check workflow permissions
    print_section "Workflow Permissions"
    check_workflow_permissions
    echo ""
    
    # Print summary
    print_section "Summary"
    echo -e "${GREEN}Passed:${NC}   $PASSED"
    echo -e "${YELLOW}Warnings:${NC} $WARNINGS"
    echo -e "${RED}Failed:${NC}   $FAILED"
    echo ""
    
    if [ $FAILED -eq 0 ]; then
        echo -e "${GREEN}✓ All critical checks passed!${NC}"
        echo ""
        echo -e "${BLUE}Next steps:${NC}"
        echo "1. Commit the Dependabot configuration files"
        echo "2. Push to GitHub"
        echo "3. Verify in repository settings"
        echo "4. Wait for the first Dependabot PR (next Monday 3 AM UTC)"
        echo ""
        echo "For more information, see: .github/DEPENDABOT_SETUP.md"
        exit 0
    else
        echo -e "${RED}✗ Some checks failed. Please fix the issues above.${NC}"
        exit 1
    fi
}

# Run main
main
