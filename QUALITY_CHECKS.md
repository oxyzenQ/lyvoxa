# 🔍 Lyvoxa Quality Assurance Guide

This document outlines the comprehensive quality check system for the Lyvoxa project.

## 🚀 Quick Start

### Setup Git Hooks (One-time)
```bash
./setup-git-hooks.sh
```

### Manual Quality Checks
```bash
# Full comprehensive check
./pre-commit.sh

# Quick check (no tests/audit)
./pre-commit.sh --quick

# Skip only tests
./pre-commit.sh --skip-tests

# Skip only security audit
./pre-commit.sh --skip-audit
```

### Using Makefile
```bash
# Full quality checks
make pre-commit

# Quick checks
make pre-commit-quick

# Setup Git hooks
make setup-hooks

# Individual checks
make quality-full    # fmt-check + clippy + test + audit
make quality-quick   # fmt-check + clippy + debug build
```

## 📋 Quality Checks Performed

### 1. Project Structure Validation
- ✅ Verifies `Cargo.toml` exists
- ✅ Ensures `Cargo.lock` is present/generated
- ✅ Validates Rust project structure

### 2. Git Status Check
- ✅ Warns about unstaged changes
- ✅ Allows user to continue or abort
- ✅ Shows which files are modified

### 3. Dependency Updates
- ✅ Runs `cargo update` to get latest compatible versions
- ✅ Ensures dependencies are current within semver constraints
- ✅ Prevents "version available" warnings

### 4. Code Formatting
- ✅ Runs `cargo fmt --check`
- ✅ Ensures consistent code style
- ❌ **Fails if formatting issues found**
- 💡 **Fix**: Run `cargo fmt`

### 5. Clippy Linting
- ✅ Runs `cargo clippy --all-targets --all-features -- -D warnings`
- ✅ Catches common mistakes and improvements
- ❌ **Fails on any clippy warnings**
- 💡 **Fix**: Run `cargo clippy --fix`

### 6. Build Verification
- ✅ Builds debug version (`cargo build`)
- ✅ Builds release version (`cargo build --release`)
- ❌ **Fails if either build fails**
- 💡 **Fix**: Fix compilation errors

### 7. Test Suite (Optional)
- ✅ Runs `cargo test`
- ✅ Ensures all tests pass
- ⏩ **Skipped in quick mode**
- ❌ **Fails if any tests fail**

### 8. Security Audit (Optional)
- ✅ Runs `cargo audit`
- ✅ Checks for security vulnerabilities
- ⏩ **Skipped in quick mode**
- ⚠️ **Warns on security issues**

### 9. Dependency Analysis
- ✅ Analyzes dependency tree depth
- ✅ Counts total dependencies
- ✅ Detects duplicate dependencies
- ⚠️ **Warns on excessive depth or duplicates**

### 10. Final Validation
- ✅ Checks release binary size
- ✅ Verifies staged files for commit
- ✅ Shows project statistics

## 🔧 Git Hooks Integration

### Pre-commit Hook
**Triggers**: On every `git commit`
**Runs**: Quick quality checks (`--quick` mode)
**Includes**:
- ✅ Project structure
- ✅ Git status
- ✅ Dependency updates
- ✅ Code formatting
- ✅ Clippy linting
- ✅ Build verification
- ⏩ Skips tests and security audit (for speed)

### Pre-push Hook
**Triggers**: On every `git push`
**Runs**: Full quality checks
**Includes**:
- ✅ All pre-commit checks
- ✅ **Plus** test suite execution
- ✅ **Plus** security audit

## 📊 Usage Examples

### Development Workflow
```bash
# Make changes
vim src/main.rs

# Quick validation before commit
make pre-commit-quick

# Stage and commit (triggers pre-commit hook)
git add .
git commit -m "feat: add new feature"

# Push (triggers pre-push hook with full checks)
git push origin main
```

### Manual Quality Assurance
```bash
# Before making a PR
./pre-commit.sh                    # Full check

# During development
./pre-commit.sh --quick            # Fast check

# Fix formatting issues
cargo fmt

# Fix clippy issues
cargo clippy --fix

# Re-run checks
./pre-commit.sh --quick
```

### CI/CD Integration
The quality checks are also integrated into GitHub Actions:
- **ci.yml**: Runs on every push to branches
- **release.yml**: Runs on tag creation

## 🎯 Error Handling

### Common Errors and Fixes

| Error | Fix |
|-------|-----|
| Formatting issues | `cargo fmt` |
| Clippy warnings | `cargo clippy --fix` or manual fixes |
| Build failures | Fix compilation errors |
| Test failures | Fix failing tests |
| Security vulnerabilities | Update dependencies or ignore if acceptable |

### Bypassing Hooks (Not Recommended)
```bash
# Skip pre-commit hook
git commit --no-verify

# Skip pre-push hook  
git push --no-verify
```

**⚠️ Warning**: Only use `--no-verify` in emergencies. The quality checks exist for good reasons!

## 📈 Quality Metrics

The script provides detailed reporting:
- **Project Information**: Name, version, toolchain
- **Repository Status**: Branch, commit hash, staged files
- **Dependency Stats**: Total count, depth analysis, duplicates
- **Binary Information**: Size analysis, optimization level
- **Check Results**: Pass/fail status for each validation

## 🔄 Maintenance

### Updating the Quality System
```bash
# Update the scripts
vim pre-commit.sh
vim setup-git-hooks.sh

# Re-install hooks after updates
./setup-git-hooks.sh

# Test the updates
./pre-commit.sh --quick
```

### Adding New Checks
Edit `pre-commit.sh` and add new validation functions following the existing pattern:
1. Create a new function (e.g., `check_new_feature()`)
2. Add it to the main execution flow
3. Update the step counter and documentation

---

**Maintained by**: rezky_nightky | **Version**: Stellar 3.0 | **Updated**: $(date -u +%Y-%m-%d)
