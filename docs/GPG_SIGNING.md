# 🔐 GPG Signing Setup

This document explains how to set up GPG signing for Lyvoxa releases.

## 📋 Table of Contents

- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Step-by-Step Setup](#step-by-step-setup)
- [GitHub Configuration](#github-configuration)
- [Verification](#verification)
- [Troubleshooting](#troubleshooting)

## 🎯 Overview

GPG signing ensures that releases are authentic and haven't been tampered with. When properly configured:

- ✅ Release artifacts are cryptographically signed
- ✅ Users can verify downloads came from the official maintainer
- ✅ Automatic signing in CI/CD pipeline
- ✅ No manual intervention required

**Files generated:**
- `lyvoxa-X.X.X-linux-amd64.tar.gz` - Binary package
- `lyvoxa-X.X.X-linux-amd64.tar.gz.sha256` - Checksum
- `lyvoxa-X.X.X-linux-amd64.tar.gz.sig` - GPG signature (binary, detached)

## ✅ Prerequisites

- GPG installed (`gpg --version`)
- GitHub repository access
- Admin permissions to set repository secrets

## 🔧 Step-by-Step Setup

### 1️⃣ Identify Your Key

```bash
# List your keys
gpg --list-secret-keys --keyid-format LONG

# Output example:
# sec   rsa4096/0D8D13BB989AF9F0 2024-01-01 [SC]
#       ABC123...DEF456
# uid   [ultimate] Your Name <your.email@example.com>
# ssb   rsa4096/XYZ789... 2024-01-01 [E]

# Your Key ID: 0D8D13BB989AF9F0
```

### 2️⃣ Export Private Key (ASCII-armored)

```bash
# Replace KEY_ID with your actual key ID
gpg --armor --export-secret-keys 0D8D13BB989AF9F0 > private-key.asc

# This file contains:
# -----BEGIN PGP PRIVATE KEY BLOCK-----
# ...
# -----END PGP PRIVATE KEY BLOCK-----
```

⚠️ **IMPORTANT**: Keep `private-key.asc` secure. Delete after setup.

### 3️⃣ Export Public Key (for users to verify)

```bash
# Export public key
gpg --armor --export 0D8D13BB989AF9F0 > public-key.asc

# Upload to keyserver (optional but recommended)
gpg --keyserver keys.openpgp.org --send-keys 0D8D13BB989AF9F0
```

## 🔐 GitHub Configuration

### 1️⃣ Add Repository Secrets

Go to: `GitHub Repo → Settings → Secrets and variables → Actions → New repository secret`

#### Secret 1: `GPG_PRIVATE_KEY`
```bash
# Copy entire content of private-key.asc
cat private-key.asc

# Paste into GitHub Secret value
```

#### Secret 2: `GPG_PASSPHRASE`
```
Your GPG key passphrase
```

### 2️⃣ Verify Secrets are Set

In GitHub:
- `Settings → Secrets and variables → Actions`
- Should see:
  - ✅ `GPG_PRIVATE_KEY`
  - ✅ `GPG_PASSPHRASE`

### 3️⃣ Workflow Configuration

The workflow is already configured in `.github/workflows/release.yml`:

```yaml
- name: Setup GPG (if available)
  if: ${{ secrets.GPG_PRIVATE_KEY != '' }}
  run: |
    echo "${{ secrets.GPG_PRIVATE_KEY }}" | gpg --batch --import
    gpg --list-secret-keys --keyid-format LONG

- name: Sign Package (GPG)
  if: ${{ secrets.GPG_PRIVATE_KEY != '' }}
  run: |
    echo "${{ secrets.GPG_PASSPHRASE }}" | gpg --batch --yes --passphrase-fd 0 \
      --pinentry-mode loopback --detach-sign $ARTIFACT.tar.gz
```

The release workflow will skip signing if `GPG_PRIVATE_KEY` is not configured.

## ✔️ Verification

### For Maintainers (Testing)

After pushing a tag:

```bash
# Check GitHub Actions logs
# Should see:
# 🔐 Setting up GPG for signing...
# ✅ GPG key imported
# 🔏 Signing package with GPG...
# ✅ Signature created: lyvoxa-X.X.X-linux-amd64.tar.gz.sig
```

### For Users (Verifying Downloads)

```bash
# Download release + signature
wget https://github.com/oxyzenQ/lyvoxa/releases/download/3.0/lyvoxa-3.1.0-linux-amd64.tar.gz
wget https://github.com/oxyzenQ/lyvoxa/releases/download/3.0/lyvoxa-3.1.0-linux-amd64.tar.gz.sig

# Import developer's public key (first time only)
gpg --keyserver hkps://keys.openpgp.org --recv-keys 0D8D13BB989AF9F0

# Verify signature
gpg --verify lyvoxa-3.1.0-linux-amd64.tar.gz.sig lyvoxa-3.1.0-linux-amd64.tar.gz

# Expected output:
# gpg: Signature made [date]
# gpg:                using RSA key 0D8D13BB989AF9F0
# gpg: Good signature from "Your Name <your.email@example.com>"
```

## 🛡️ Security Best Practices

### ✅ Do's

- ✅ Use a **strong passphrase** (20+ characters)
- ✅ Use a **subkey** specifically for signing (advanced)
- ✅ **Upload public key** to keyservers
- ✅ **Backup private key** securely offline
- ✅ Set **key expiration** (renew yearly)
- ✅ **Delete** `private-key.asc` after setup

### ❌ Don'ts

- ❌ **Never commit** private keys to git
- ❌ **Never share** your private key
- ❌ **Never hardcode** passphrases in code
- ❌ **Don't use** master key directly (use subkey)
- ❌ **Don't skip** passphrase protection

## 🔧 Troubleshooting

### Issue: "gpg: signing failed: Inappropriate ioctl for device"

**Solution**: Use `--pinentry-mode loopback`
```bash
gpg --batch --yes --passphrase-fd 0 --pinentry-mode loopback --armor --detach-sign file.tar.gz
```

### Issue: "No secret key"

**Solution**: Key not imported properly
```bash
# Re-import private key
echo "$GPG_PRIVATE_KEY" | gpg --batch --import

# Verify
gpg --list-secret-keys
```

### Issue: "Signature verification fails"

**Solution**: Public key not imported
```bash
# Import from keyserver
gpg --keyserver keys.openpgp.org --recv-keys YOUR_KEY_ID

# Or import from file
gpg --import public-key.asc
```

### Issue: Release works but no .sig file

**Check:**
1. Secrets are set correctly in GitHub
2. Workflow logs for errors
3. GPG key has signing capability (`[S]`)

## 📚 Additional Resources

- [GnuPG Manual](https://www.gnupg.org/documentation/manuals/gnupg/)
- [GitHub Encrypted Secrets](https://docs.github.com/en/actions/security-guides/encrypted-secrets)
- [Keyserver Network](https://keys.openpgp.org/)

## 📝 Summary

**Before Setup:**
```
Assets:
├── lyvoxa-3.1.0-linux-amd64.tar.gz
└── lyvoxa-3.1.0-linux-amd64.tar.gz.sha256
```

**After Setup:**
```
Assets:
├── lyvoxa-3.1.0-linux-amd64.tar.gz
├── lyvoxa-3.1.0-linux-amd64.tar.gz.sha256
└── lyvoxa-3.1.0-linux-amd64.tar.gz.sig          ← GPG signature (binary)
```

**Verification Chain:**
```
SHA256 → Integrity (file not corrupted)
GPG    → Authenticity (file from official maintainer)
```

---

**Author**: Lyvoxa Maintainers
**Last Updated**: October 2025
**Version**: Stellar 3.0
