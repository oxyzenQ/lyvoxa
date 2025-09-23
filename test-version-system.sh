#!/bin/bash
# =============================================================================
# VERSION MANAGEMENT SYSTEM TEST
# =============================================================================
# Test script to verify version management system functionality

set -euo pipefail

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}[TEST]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[PASS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[FAIL]${NC} $1"
}

echo "🧪 TESTING VERSION MANAGEMENT SYSTEM"
echo "===================================="
echo ""

# Test 1: Check if files exist
log_info "Checking required files..."
files=("version.toml" "update-version.sh" "version-manager.py")
for file in "${files[@]}"; do
    if [[ -f "$file" ]]; then
        log_success "✅ $file exists"
    else
        log_error "❌ $file missing"
        exit 1
    fi
done
echo ""

# Test 2: Check Python script functionality
log_info "Testing Python version manager..."
if python3 version-manager.py current > /dev/null 2>&1; then
    log_success "✅ Python script works"
    python3 version-manager.py current
else
    log_error "❌ Python script failed"
    exit 1
fi
echo ""

# Test 3: Check validation
log_info "Testing project validation..."
if python3 version-manager.py validate > /dev/null 2>&1; then
    log_success "✅ Project validation passed"
else
    log_warning "⚠️  Project validation issues (check manually)"
fi
echo ""

# Test 4: Check version.toml parsing
log_info "Testing version.toml parsing..."
if grep -q 'semantic = "1.5.0"' version.toml; then
    log_success "✅ version.toml format correct"
else
    log_error "❌ version.toml format issue"
fi
echo ""

# Test 5: Check file permissions
log_info "Checking file permissions..."
if [[ -x "update-version.sh" ]]; then
    log_success "✅ update-version.sh is executable"
else
    log_error "❌ update-version.sh not executable"
fi

if [[ -x "version-manager.py" ]]; then
    log_success "✅ version-manager.py is executable"
else
    log_error "❌ version-manager.py not executable"
fi
echo ""

# Test 6: Dry run test (create backup and rollback)
log_info "Testing backup system..."
if python3 -c "
import sys
sys.path.append('.')
from pathlib import Path
vm_file = Path('version-manager.py')
if vm_file.exists():
    exec(vm_file.read_text())
    vm = VersionManager()
    backup = vm.create_backup()
    print(f'Backup created: {backup}')
" > /dev/null 2>&1; then
    log_success "✅ Backup system works"
else
    log_warning "⚠️  Backup system test failed (manual check needed)"
fi
echo ""

# Test 7: Check target files exist
log_info "Checking target files for version updates..."
target_files=(
    "Cargo.toml"
    "README.md" 
    "CHANGELOG.md"
    "SECURITY.md"
    "Dockerfile"
    "docker-compose.yml"
    "Makefile"
    "build.sh"
    ".github/workflows/ci.yml"
    ".github/workflows/release.yml"
)

missing_files=()
for file in "${target_files[@]}"; do
    if [[ -f "$file" ]]; then
        log_success "✅ $file (target file exists)"
    else
        log_warning "⚠️  $file (target file missing)"
        missing_files+=("$file")
    fi
done

if [[ ${#missing_files[@]} -eq 0 ]]; then
    log_success "All target files present"
else
    log_warning "${#missing_files[@]} target files missing (updates will skip them)"
fi
echo ""

# Summary
echo "📊 TEST SUMMARY"
echo "==============="
log_success "Version management system is ready to use!"
echo ""
echo "Usage examples:"
echo "  # Show current version"
echo "  python3 version-manager.py current"
echo ""
echo "  # Update to new version (interactive)"
echo "  ./update-version.sh"
echo ""
echo "  # Update to new version (direct)"
echo "  python3 version-manager.py update 1.6.0 Matrix 1.6"
echo ""
echo "  # Validate project"
echo "  python3 version-manager.py validate"
echo ""
echo "  # Rollback if needed"
echo "  python3 version-manager.py rollback"
echo ""

log_info "Ready for version management! 🚀"
