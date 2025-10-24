# 🏗️ AUR Setup Guide - Complete Walkthrough

Professional AUR automation setup for `lyvoxa-bin` package.

## 🎯 Architecture

```
GitHub (Single Source of Truth)
    ├── lyvoxa-bin/PKGBUILD
    ├── lyvoxa-bin/.SRCINFO
    └── .github/workflows/aur-release.yml
           ↓ (Auto-sync on push)
    AUR Repository
        └── ssh://aur@aur.archlinux.org/lyvoxa-bin.git
           ↓ (Users install)
    Arch Linux Systems
        └── yay -S lyvoxa-bin
```

**Philosophy**: Edit once in GitHub, auto-push to AUR. Zero manual work.

---

## 📋 Prerequisites

- [x] AUR account created
- [x] GPG key configured  
- [x] GitHub repository with release workflow
- [x] Releases published with .tar.gz + .sha256 + .asc

---

## 🔑 Step 1: Generate SSH Key for AUR

```bash
# Generate dedicated SSH key for AUR
ssh-keygen -t ed25519 -f ~/.ssh/aur -C "AUR access for lyvoxa"

# Output:
# ~/.ssh/aur       (private key - KEEP SECRET)
# ~/.ssh/aur.pub   (public key - upload to AUR)
```

**Important**: Use passphrase for extra security (optional but recommended).

---

## 🌐 Step 2: Add Public Key to AUR

1. Login to https://aur.archlinux.org
2. Click your username → **"My Account"**
3. Find section: **"SSH Public Key"**
4. Paste content of `~/.ssh/aur.pub`:
   ```bash
   cat ~/.ssh/aur.pub
   ```
5. Click **"Update"**

**Verification:**
```bash
ssh -T aur@aur.archlinux.org
```

Expected output:
```
PTY allocation request failed on channel 0
```
This is normal! It means key is accepted.

---

## 📦 Step 3: Create Package on AUR (First Time Only)

### Option A: Via Web Interface

1. Go to https://aur.archlinux.org/submit
2. Upload a tarball containing:
   - `PKGBUILD`
   - `.SRCINFO`
   
   ```bash
   cd lyvoxa-bin
   makepkg --printsrcinfo > .SRCINFO
   tar czf lyvoxa-bin.tar.gz PKGBUILD .SRCINFO
   ```
3. Upload `lyvoxa-bin.tar.gz`

### Option B: Via Git (Recommended)

```bash
# Clone empty AUR repo (will fail if package doesn't exist yet)
git clone ssh://aur@aur.archlinux.org/lyvoxa-bin.git
cd lyvoxa-bin

# Copy files from your GitHub repo
cp ../lyvoxa/lyvoxa-bin/PKGBUILD .
cp ../lyvoxa/lyvoxa-bin/.SRCINFO .

# Initial commit
git add PKGBUILD .SRCINFO
git commit -m "Initial commit: lyvoxa-bin 3.0.1"
git push origin master
```

**First push creates the package!**

---

## 🔐 Step 4: Add SSH Key to GitHub Secrets

1. Go to GitHub repository → **Settings** → **Secrets and variables** → **Actions**

2. Click **"New repository secret"**

3. Add secret:
   - **Name**: `AUR_SSH_PRIVATE_KEY`
   - **Value**: Content of private key
   
   ```bash
   cat ~/.ssh/aur
   ```
   
   Copy **entire output** including:
   ```
   -----BEGIN OPENSSH PRIVATE KEY-----
   ...
   -----END OPENSSH PRIVATE KEY-----
   ```

4. Click **"Add secret"**

**Security**: This private key is encrypted by GitHub and only accessible to your workflows.

---

## 🧪 Step 5: Test the Workflow

### Method 1: Edit PKGBUILD

```bash
cd lyvoxa-bin
# Make a small change (e.g., bump pkgrel)
vim PKGBUILD

# Regenerate .SRCINFO
makepkg --printsrcinfo > .SRCINFO

# Commit and push
git add PKGBUILD .SRCINFO
git commit -m "test: trigger AUR sync"
git push origin main
```

### Method 2: Manual Workflow Trigger

1. Go to **Actions** → **AUR Release**
2. Click **"Run workflow"**
3. Select branch: `main`
4. Click **"Run workflow"**

**Expected Result:**
- Workflow runs in ~1-2 minutes
- PKGBUILD and .SRCINFO synced to AUR
- Changes visible at: https://aur.archlinux.org/packages/lyvoxa-bin

---

## 🎯 Step 6: Verify AUR Package

### Check Package Page

Visit: https://aur.archlinux.org/packages/lyvoxa-bin

Should show:
- ✅ Package Name: lyvoxa-bin
- ✅ Version: 3.0.1-1
- ✅ Maintainer: Your AUR username
- ✅ Last Updated: Recent timestamp

### Test Installation

```bash
# Using yay
yay -S lyvoxa-bin

# Or paru
paru -S lyvoxa-bin

# Manual
git clone https://aur.archlinux.org/lyvoxa-bin.git
cd lyvoxa-bin
makepkg -si
```

**Verification Steps:**

1. **SHA256 Check**: Should pass automatically
   ```
   ==> Verifying SHA256 checksum...
   lyvoxa-3.0.1-linux-amd64.tar.gz: OK
   ```

2. **GPG Verification**: May show warning first time
   ```
   ==> Verifying GPG signature...
   gpg: Good signature from "Rezky Cahya Sahputra..."
   ```

3. **Installation**: Binary installed to `/usr/bin/lyvoxa`
   ```bash
   which lyvoxa
   lyvoxa --version
   ```

---

## 🔄 Daily Workflow (After Setup)

### Updating the Package

When you release new version (e.g., 3.0.2):

1. **GitHub Release workflow** creates:
   - `lyvoxa-3.0.2-linux-amd64.tar.gz`
   - `lyvoxa-3.0.2-linux-amd64.tar.gz.sha256`
   - `lyvoxa-3.0.2-linux-amd64.tar.gz.asc`

2. **Update PKGBUILD**:
   ```bash
   cd lyvoxa-bin
   vim PKGBUILD
   # Change: pkgver=3.0.2
   # Reset: pkgrel=1
   ```

3. **Regenerate .SRCINFO**:
   ```bash
   makepkg --printsrcinfo > .SRCINFO
   ```

4. **Commit and push**:
   ```bash
   git add PKGBUILD .SRCINFO
   git commit -m "chore(aur): update to 3.0.2"
   git push
   ```

5. **AUR workflow auto-syncs** in ~2 minutes! 🚀

**That's it!** No manual AUR interaction needed.

---

## 🛠️ Troubleshooting

### Issue: SSH Permission Denied

**Error:**
```
Permission denied (publickey).
fatal: Could not read from remote repository.
```

**Solution:**
1. Verify public key is added to AUR account
2. Test SSH connection:
   ```bash
   ssh -v aur@aur.archlinux.org
   ```
3. Check SSH config:
   ```bash
   cat ~/.ssh/config
   ```
   Should have:
   ```
   Host aur.archlinux.org
       IdentityFile ~/.ssh/aur
       User aur
   ```

### Issue: GPG Verification Failed

**Warning:**
```
gpg: Can't check signature: No public key
```

**Solution for users:**
```bash
gpg --keyserver hkps://keys.openpgp.org --recv-keys 0D8D13BB989AF9F0
```

**Note**: This is just a warning for users who haven't imported your key. Installation will still proceed.

### Issue: .SRCINFO Out of Date

**Error:**
```
==> ERROR: .SRCINFO is out of date
```

**Solution:**
```bash
cd lyvoxa-bin
makepkg --printsrcinfo > .SRCINFO
git add .SRCINFO
git commit -m "chore: regenerate .SRCINFO"
git push
```

### Issue: Workflow Fails - "Repository not found"

**Error:**
```
fatal: Could not read from 'ssh://aur@aur.archlinux.org/lyvoxa-bin.git'
```

**Solution:**
Package doesn't exist on AUR yet. Create it first (Step 3 above).

---

## 📊 Monitoring

### Check Workflow Status

**GitHub Actions:**
```
https://github.com/oxyzenQ/lyvoxa/actions/workflows/aur-release.yml
```

### Check AUR Package

**Package Page:**
```
https://aur.archlinux.org/packages/lyvoxa-bin
```

**Git Log:**
```bash
git clone https://aur.archlinux.org/lyvoxa-bin.git
cd lyvoxa-bin
git log --oneline
```

### Check User Feedback

**Comments Section:**
```
https://aur.archlinux.org/packages/lyvoxa-bin#comment-form
```

Respond to user issues professionally and promptly.

---

## 🎓 Best Practices

### 1. Semantic Versioning

- `pkgver` = Upstream version (3.0.1)
- `pkgrel` = Package revision (1, 2, 3...)

**When to bump `pkgrel`:**
- PKGBUILD fixes (e.g., install path change)
- Dependency changes
- No upstream version change

**When to bump `pkgver`:**
- New upstream release
- Reset `pkgrel=1` when `pkgver` changes

### 2. Commit Messages

Use descriptive messages:

```bash
# Good
git commit -m "chore(aur): update to 3.0.2"
git commit -m "fix(aur): correct install path for documentation"

# Bad
git commit -m "update"
git commit -m "fix"
```

### 3. Testing Before Push

Always test locally first:

```bash
cd lyvoxa-bin
makepkg -si
```

Only push if installation succeeds.

### 4. Responding to Comments

- Check AUR comments weekly
- Respond within 48 hours
- Be professional and helpful
- Update package if issues found

---

## 🚀 Advanced: Multi-Package Setup

If you want to maintain multiple AUR packages:

```
lyvoxa/
├── lyvoxa-bin/      # Precompiled binary
├── lyvoxa-git/      # Build from git
└── .github/workflows/
    └── aur-release.yml   # Auto-sync all packages
```

Workflow can detect which folder changed and sync only that package!

---

## 📚 Resources

- **AUR Guidelines**: https://wiki.archlinux.org/title/AUR_submission_guidelines
- **PKGBUILD Manual**: https://wiki.archlinux.org/title/PKGBUILD
- **makepkg**: https://wiki.archlinux.org/title/Makepkg
- **GPG**: https://wiki.archlinux.org/title/GnuPG

---

## ✅ Checklist

- [ ] SSH key generated
- [ ] Public key added to AUR account
- [ ] Package created on AUR (initial push)
- [ ] Private key added to GitHub Secrets
- [ ] Workflow tested successfully
- [ ] Package installs correctly
- [ ] GPG verification works
- [ ] README.md updated

---

## 🎉 Success!

You now have **professional-grade AUR automation**!

**What you achieved:**
- ✅ Single source of truth (GitHub)
- ✅ Zero manual AUR maintenance
- ✅ Automatic sync on every push
- ✅ GPG signature verification
- ✅ SHA256 integrity checks
- ✅ Industry-standard workflow

**Maintenance effort:** ~1 minute per release (just bump version).

**That's the power of automation!** 🚀

---

*Automated with ❤️ by GitHub Actions*  
*Maintained by Rezky Cahya Sahputra*
