# Lyvoxa Maintenance Guide

## Overview

The `lyvoxa-maintain.sh` script is the unified maintenance tool for Lyvoxa project. It consolidates all maintenance tasks into a single, easy-to-use interface.

## Quick Start

```bash
# Show help
./lyvoxa-maintain.sh help

# First-time setup
./lyvoxa-maintain.sh setup

# Update dependencies
./lyvoxa-maintain.sh update-deps

# Check current version
./lyvoxa-maintain.sh version

# Update version
./lyvoxa-maintain.sh update-version
```

## Commands

### `setup` - Git Hooks Setup

Sets up automated quality checks via Git hooks.

**What it does:**
- Creates pre-commit hook (runs quality checks)
- Creates commit-msg hook (validates conventional commits)
- Makes hooks executable
- Tests hook installation

**Usage:**
```bash
./lyvoxa-maintain.sh setup
```

**When to use:**
- First time setting up the project
- After cloning the repository
- If hooks get accidentally deleted

### `update-deps` - Dependency Updates

Updates and audits all Cargo dependencies.

**What it does:**
- Runs `cargo update` to update dependencies
- Shows outdated packages (if cargo-outdated installed)
- Runs security audit (if cargo-audit installed)
- Reports any vulnerabilities

**Usage:**
```bash
./lyvoxa-maintain.sh update-deps
```

**When to use:**
- Weekly maintenance routine
- Before major releases
- After Dependabot PRs are merged
- When security vulnerabilities are reported

**Optional tools for enhanced functionality:**
```bash
# Install for detailed outdated package info
cargo install cargo-outdated

# Install for security auditing
cargo install cargo-audit
```

### `version` - Show Version

Displays current version information.

**What it shows:**
- Semantic version (e.g., 3.0.0)
- Release name (e.g., Stellar)
- Release number (e.g., 3.0)
- Release tag (e.g., stellar-3.0)

**Usage:**
```bash
./lyvoxa-maintain.sh version
```

### `update-version` - Version Update Wizard

Interactive wizard to update version across entire project.

**What it does:**
- Prompts for new version, release name, and release number
- Validates semantic versioning format
- Updates `version.toml`
- Updates `Cargo.toml`
- Updates `README.md`
- Updates all workflow files (`.github/workflows/*.yml`)
- Updates all shell scripts (`*.sh`)
- Shows modified files

**Usage:**
```bash
./lyvoxa-maintain.sh update-version
```

**Example session:**
```
Current version: 3.0.0 (Stellar 3.0)

Enter new version (e.g., 3.1.0): 3.1.0
Enter release name (e.g., Stellar): Stellar
Enter release number (e.g., 3.1): 3.1

Will update:
  Version: 3.0.0 → 3.1.0
  Release: Stellar 3.0 → Stellar 3.1

Continue? (y/N): y
```

**After updating:**
1. Update `CHANGELOG.md` with release notes
2. Run `cargo build --release` to test
3. Test the build
4. Commit: `git add -A && git commit -m "chore(release): bump to 3.1.0"`
5. Push and create release tag

### `all` - Run All Setup Tasks

Runs setup and dependency update in sequence.

**Usage:**
```bash
./lyvoxa-maintain.sh all
```

**When to use:**
- Initial project setup
- Setting up development environment
- After major updates

## Maintenance Workflows

### Weekly Maintenance

```bash
# Update dependencies
./lyvoxa-maintain.sh update-deps

# Run tests
cargo test

# Check for outdated packages
cargo outdated
```

### Pre-Release Checklist

1. **Update version**
   ```bash
   ./lyvoxa-maintain.sh update-version
   ```

2. **Update CHANGELOG.md**
   - Document new features
   - Document bug fixes
   - Document breaking changes

3. **Update dependencies**
   ```bash
   ./lyvoxa-maintain.sh update-deps
   ```

4. **Run full test suite**
   ```bash
   cargo test
   cargo clippy --all-targets --all-features
   ./pre-commit.sh
   ```

5. **Build and test**
   ```bash
   cargo build --release
   ./target/x86_64-unknown-linux-gnu/release/lyvoxa --version
   ```

6. **Commit and tag**
   ```bash
   git add -A
   git commit -m "chore(release): bump to X.Y.Z"
   git tag -a vX.Y.Z -m "Release vX.Y.Z"
   git push origin main --tags
   ```

### New Developer Setup

```bash
# Clone repository
git clone https://github.com/oxyzenQ/lyvoxa.git
cd lyvoxa

# Setup environment
./lyvoxa-maintain.sh setup

# Update dependencies
./lyvoxa-maintain.sh update-deps

# Build project
cargo build --release

# Run tests
cargo test
```

## Troubleshooting

### Git hooks not running

```bash
# Re-run setup
./lyvoxa-maintain.sh setup

# Verify hooks are executable
ls -la .git/hooks/
```

### Dependency update fails

```bash
# Clean build cache
cargo clean

# Try update again
./lyvoxa-maintain.sh update-deps
```

### Version update not applied everywhere

The script updates:
- `version.toml`
- `Cargo.toml`
- `README.md`
- All `.github/workflows/*.yml` files
- All `*.sh` scripts

If something was missed, manually search and replace:
```bash
grep -r "old_version" .
```

## Integration with Other Tools

### Dependabot

The maintenance tool works alongside Dependabot:
- Dependabot updates individual packages
- `update-deps` updates all packages at once
- Both are complementary

### CI/CD

The maintenance tool mirrors CI checks:
- Git hooks use same checks as CI
- Ensures local testing matches CI
- Catches issues before pushing

### Makefile

The tool is also available via Makefile:
```bash
make setup        # Run setup
make update-deps  # Update dependencies
```

## Migration from Old Scripts

**Old scripts (deprecated):**
- ❌ `setup-git-hooks.sh`
- ❌ `update-deps.sh`
- ❌ `update-version.sh`
- ❌ `version-manager.py`

**New unified tool:**
- ✅ `lyvoxa-maintain.sh`

All functionality is preserved and enhanced in the new tool.

## Best Practices

1. **Run setup once** after cloning
2. **Update deps weekly** or before releases
3. **Use version wizard** for consistent versioning
4. **Test locally** before pushing
5. **Follow conventional commits** enforced by git hooks

## Support

- **Issues**: https://github.com/oxyzenQ/lyvoxa/issues
- **Documentation**: See `docs/` directory
- **Help**: `./lyvoxa-maintain.sh help`

---

**Version**: Stellar 3.0  
**Maintained by**: @oxyzenQ
