# 🔄 Version Management System

Lyvoxa uses a centralized version management system that automatically updates version numbers across all project files from a single source of truth.

## 📋 Overview

The version management system consists of:

- **`version.toml`**: Central configuration file
- **`update-version.sh`**: Bash script for version updates
- **`version-manager.py`**: Advanced Python script with validation and rollback
- **Automated file updates**: Updates 11+ project files automatically

## 🚀 Quick Start

### Method 1: Interactive Update (Bash)
```bash
# Interactive mode - prompts for input
./update-version.sh

# Direct mode - provide all parameters
./update-version.sh "1.6.0" "Matrix" "1.6"
```

### Method 2: Advanced Management (Python)
```bash
# Show current version
python3 version-manager.py current

# Update version with validation
python3 version-manager.py update 1.6.0 Matrix 1.6

# Validate project state
python3 version-manager.py validate

# Rollback to previous version
python3 version-manager.py rollback
```

## 📁 Files Updated Automatically

The system updates version information in:

| File | Updates |
|------|---------|
| `Cargo.toml` | Semantic version |
| `README.md` | Version display, download URLs |
| `CHANGELOG.md` | New version entry |
| `SECURITY.md` | Download URLs and references |
| `Dockerfile` | Version labels and comments |
| `docker-compose.yml` | Image tags |
| `Makefile` | Version comments |
| `build.sh` | Version display |
| `.github/workflows/ci.yml` | Release tags |
| `.github/workflows/release.yml` | Default version |
| `docs/SETUP_SSH_SIGNING.md` | Example URLs |

## 🔧 Configuration

### version.toml Structure
```toml
[version]
semantic = "1.5.0"           # Semantic version (major.minor.patch)
release_name = "Stellar"     # Release series name
release_number = "1.5"       # Release number
release_tag = "stellar-1.5"  # Git tag format

[metadata]
project_name = "lyvoxa"
author = "rezky_nightky"
license = "GPL-3.0"
repository = "https://github.com/oxyzenQ/lyvoxa"

[files]
# List of files to update (automatically detected)
```

## 📊 Version Naming Convention

Lyvoxa uses themed release names:

| Series | Theme | Example Versions |
|--------|-------|------------------|
| **Stellar** | Space/Stars | stellar-1.5, stellar-1.6 |
| **Matrix** | Digital/Cyber | matrix-2.0, matrix-2.1 |
| **Quantum** | Physics | quantum-3.0, quantum-3.1 |
| **Dark** | Mystery | dark-4.0, dark-4.1 |

## 🛡️ Safety Features

### Automatic Backups
- Creates timestamped backups before updates
- Stored in `.version-backups/` directory
- Includes all modified files

### Validation
- Semantic version format checking
- Cargo.toml syntax validation
- Project build verification
- File integrity checks

### Rollback System
```bash
# Automatic rollback on failure
python3 version-manager.py update 1.6.0 Matrix 1.6

# Manual rollback to latest backup
python3 version-manager.py rollback
```

## 🔄 Workflow Integration

### Standard Release Process
```bash
# 1. Update version
python3 version-manager.py update 1.6.0 Matrix 1.6

# 2. Review changes
git diff

# 3. Test build
./build.sh release

# 4. Commit and tag
git add .
git commit -m "bump: version 1.6.0 (Matrix 1.6)"
git tag -a matrix-1.6 -m "Matrix 1.6 Release"

# 5. Push to trigger CI/CD
git push origin main
git push origin matrix-1.6
```

### CI/CD Integration
The version update automatically triggers:
- GitHub Actions workflows
- Docker image builds with new tags
- Release artifact generation
- Documentation updates

## 🎯 Examples

### Major Version Update
```bash
# Update to new major version
./update-version.sh "2.0.0" "Matrix" "2.0"
```

### Minor Version Update
```bash
# Update minor version in same series
./update-version.sh "1.6.0" "Stellar" "1.6"
```

### Patch Version Update
```bash
# Bug fix release
./update-version.sh "1.5.1" "Stellar" "1.5.1"
```

## 🔍 Troubleshooting

### Common Issues

#### Version Format Error
```bash
# ❌ Invalid format
./update-version.sh "1.6" "Matrix" "1.6"

# ✅ Correct format
./update-version.sh "1.6.0" "Matrix" "1.6"
```

#### Build Validation Failure
```bash
# Check what failed
python3 version-manager.py validate

# Manual rollback if needed
python3 version-manager.py rollback
```

#### Missing Files
```bash
# Check which files exist
ls -la Cargo.toml README.md CHANGELOG.md

# Update only existing files (automatic)
```

### Recovery Options

#### Restore from Backup
```bash
# List available backups
ls -la .version-backups/

# Restore specific backup
python3 version-manager.py rollback .version-backups/backup_20250124_143022
```

#### Manual Fix
```bash
# Edit version.toml manually
nano version.toml

# Re-run update
python3 version-manager.py update 1.6.0 Matrix 1.6
```

## 🏗️ Architecture

### Script Comparison

| Feature | update-version.sh | version-manager.py |
|---------|-------------------|-------------------|
| **Language** | Bash | Python |
| **Validation** | Basic | Advanced |
| **Backups** | Simple | Timestamped |
| **Rollback** | Manual | Automatic |
| **Error Handling** | Basic | Comprehensive |
| **Dependencies** | None | Python 3.6+ |

### File Pattern System
```python
# Example pattern for README.md
patterns = [
    (r'\*\*Current Version\*\*: [^(]+\(v[^)]+\)', 
     r'**Current Version**: {release_name} {release_number} (v{version})'),
    (r'stellar-1\.5', r'{release_tag}')
]
```

## 📚 Best Practices

### Version Planning
1. **Major versions**: Breaking changes, new architecture
2. **Minor versions**: New features, significant improvements  
3. **Patch versions**: Bug fixes, security updates

### Release Naming
1. Choose meaningful theme names
2. Use consistent numbering scheme
3. Document naming convention
4. Plan series progression

### Testing
1. Always test build after version update
2. Verify all URLs and references
3. Check Docker builds
4. Test installation scripts

---

**Maintained by**: rezky_nightky | **Last Updated**: 2025-01-24 | **Version**: Stellar 1.5
