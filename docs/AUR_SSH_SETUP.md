# 🔑 Complete Guide: Setting Up SSH Key for AUR Bot

## 📋 Overview

This guide walks you through creating a passwordless SSH key for automated AUR package publishing via GitHub Actions.

---

## 🚀 Step 1: Generate SSH Key (Without Password)

Open your terminal and run:

```bash
# Generate Ed25519 SSH key (modern, secure, and compact)
ssh-keygen -t ed25519 -C "lyvoxa-bot@github-actions" -f ~/.ssh/aur_bot_ed25519 -N ""
```

**Parameters explained:**
- `-t ed25519` - Use modern Ed25519 algorithm (faster and more secure than RSA)
- `-C "lyvoxa-bot@github-actions"` - Comment to identify the key
- `-f ~/.ssh/aur_bot_ed25519` - Custom filename to avoid overwriting your personal key
- `-N ""` - No passphrase (empty password for automation)

**Output:**
```
Generating public/private ed25519 key pair.
Your identification has been saved in ~/.ssh/aur_bot_ed25519
Your public key has been saved in ~/.ssh/aur_bot_ed25519.pub
The key fingerprint is:
SHA256:xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx lyvoxa-bot@github-actions
```

---

## 🔐 Step 2: Add Public Key to AUR Account

### 2.1 Copy your public key:

```bash
cat ~/.ssh/aur_bot_ed25519.pub
```

**Example output:**
```
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAbCdEfG... lyvoxa-bot@github-actions
```

Copy this **entire line** (starts with `ssh-ed25519`).

### 2.2 Add to AUR:

1. Go to [AUR Account Settings](https://aur.archlinux.org/account/)
2. Log in to your AUR account
3. Navigate to **"My Account"** → **"SSH Public Key"**
4. Paste your public key in the text area
5. Click **"Update"**

### 2.3 Test SSH connection:

```bash
ssh -T -i ~/.ssh/aur_bot_ed25519 aur@aur.archlinux.org
```

**Expected output:**
```
Hi username! You've successfully authenticated, but AUR does not provide shell access.
```

✅ If you see this message, SSH is configured correctly!

---

## 🔧 Step 3: Add Private Key to GitHub Secrets

### 3.1 Display your private key:

```bash
cat ~/.ssh/aur_bot_ed25519
```

**Output looks like:**
```
-----BEGIN OPENSSH PRIVATE KEY-----
b3BlbnNzaC1rZXktdjEAAAAABG5vbmUAAAAEbm9uZQAAAAAAAAABAAAAMwAAAAtzc2gtZW
QyNTUxOQAAACAABsJ0R8aIjqXyZ...
...multiple lines...
-----END OPENSSH PRIVATE KEY-----
```

**Copy the ENTIRE key** including:
- `-----BEGIN OPENSSH PRIVATE KEY-----`
- All the encoded lines
- `-----END OPENSSH PRIVATE KEY-----`

### 3.2 Add to GitHub:

1. Go to your GitHub repository: `https://github.com/oxyzenQ/lyvoxa`
2. Click **Settings** → **Secrets and variables** → **Actions**
3. Click **"New repository secret"**
4. Set:
   - **Name:** `AUR_SSH_PRIVATE_KEY`
   - **Value:** Paste the entire private key (including BEGIN/END lines)
5. Click **"Add secret"**

---

## ✅ Step 4: Verify GitHub Actions Configuration

Your `aur-release.yml` workflow should have this structure:

```yaml
- name: Setup SSH for AUR
  env:
    AUR_SSH_PRIVATE_KEY: ${{ secrets.AUR_SSH_PRIVATE_KEY }}
  run: |
    mkdir -p ~/.ssh
    echo "$AUR_SSH_PRIVATE_KEY" > ~/.ssh/id_ed25519
    chmod 600 ~/.ssh/id_ed25519
    
    cat > ~/.ssh/config << 'EOF'
    Host aur.archlinux.org
      User aur
      IdentityFile ~/.ssh/id_ed25519
      StrictHostKeyChecking accept-new
    EOF
    
    chmod 600 ~/.ssh/config
```

✅ This is already configured in your workflow!

---

## 🧪 Step 5: Test the Workflow

### Option A: Trigger manually

```bash
# Go to GitHub Actions tab
# Select "📦 AUR Sync" workflow
# Click "Run workflow"
```

### Option B: Create a test release

```bash
git tag v3.1.0-test
git push origin v3.1.0-test
```

This will trigger:
1. `🌟 Release` workflow
2. `📦 AUR Sync` workflow (automatically after release)

---

## 🛡️ Security Best Practices

### ✅ DO:
- ✅ Use Ed25519 keys (modern, secure)
- ✅ Keep private keys in GitHub Secrets (encrypted)
- ✅ Use passwordless keys for automation (no human interaction)
- ✅ Limit key scope to AUR only
- ✅ Rotate keys periodically (every 6-12 months)

### ❌ DON'T:
- ❌ Share private keys via email, Slack, or public channels
- ❌ Commit private keys to git (even in `.gitignore`)
- ❌ Reuse personal SSH keys for automation
- ❌ Add passwords to automation keys (breaks CI/CD)

---

## 🔍 Troubleshooting

### Problem: "Permission denied (publickey)"

**Cause:** Public key not added to AUR or wrong private key in GitHub.

**Solution:**
```bash
# 1. Verify public key is in AUR account settings
# 2. Test SSH locally:
ssh -T -i ~/.ssh/aur_bot_ed25519 aur@aur.archlinux.org

# 3. Check GitHub secret contains FULL private key (including BEGIN/END)
```

---

### Problem: "Bad owner or permissions on ~/.ssh/config"

**Cause:** Wrong file permissions.

**Solution:**
```bash
chmod 600 ~/.ssh/id_ed25519
chmod 600 ~/.ssh/config
```

---

### Problem: "Host key verification failed"

**Cause:** First-time connection, SSH doesn't trust AUR's host key.

**Solution:** Already handled by `StrictHostKeyChecking accept-new` in workflow.

---

### Problem: "Could not resolve hostname"

**Cause:** Network/DNS issue.

**Solution:** Check GitHub Actions runner has internet access (should work by default).

---

## 📦 AUR Package Update Flow

```
┌─────────────────────────────────────────────────────────────┐
│  Developer pushes tag (v3.1.0)                              │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│  🤖 Version Bump Bot: Updates version in files              │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│  🔧 CI Pipeline: Build, test, security checks               │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│  🌟 Release: Creates GitHub release + binaries              │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│  📦 AUR Sync:                                               │
│  1. Detects new version                                     │
│  2. Downloads release binaries                              │
│  3. Calculates SHA256 checksums                             │
│  4. Updates PKGBUILD (pkgver, sha256sums)                   │
│  5. Generates .SRCINFO                                      │
│  6. Commits to AUR with SSH                                 │
│  7. Pushes to aur.archlinux.org                             │
└─────────────────────────────────────────────────────────────┘
```

---

## 📝 Quick Reference Commands

```bash
# Generate new SSH key (passwordless)
ssh-keygen -t ed25519 -C "lyvoxa-bot@github-actions" -f ~/.ssh/aur_bot_ed25519 -N ""

# Show public key (add to AUR)
cat ~/.ssh/aur_bot_ed25519.pub

# Show private key (add to GitHub Secrets)
cat ~/.ssh/aur_bot_ed25519

# Test SSH connection
ssh -T -i ~/.ssh/aur_bot_ed25519 aur@aur.archlinux.org

# Clone your AUR package (test)
git clone ssh://aur@aur.archlinux.org/lyvoxa-bin.git

# Trigger workflow manually
gh workflow run "📦 AUR Sync"
```

---

## 🎯 Success Checklist

- [ ] Generated Ed25519 SSH key without password
- [ ] Added public key to AUR account
- [ ] Tested SSH connection locally (see "Hi username!" message)
- [ ] Added private key to GitHub Secrets as `AUR_SSH_PRIVATE_KEY`
- [ ] Verified workflow has correct SSH setup steps
- [ ] Tested workflow by triggering manually or creating release
- [ ] Checked AUR package repository for automated commit
- [ ] Verified `.SRCINFO` was properly generated

---

## 🆘 Need Help?

- **AUR SSH Documentation:** https://wiki.archlinux.org/title/AUR_submission_guidelines
- **GitHub Actions Secrets:** https://docs.github.com/en/actions/security-guides/encrypted-secrets
- **SSH Key Generation:** https://docs.github.com/en/authentication/connecting-to-github-with-ssh/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent

---

**Made with 🔥 for automated AUR publishing**
