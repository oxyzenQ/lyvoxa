# 🚀 Quick Start: AUR SSH Setup

## 📝 TL;DR - 3 Steps to Success

### Step 1: Generate SSH Key (30 seconds)
```bash
ssh-keygen -t ed25519 -C "lyvoxa-bot@github-actions" -f ~/.ssh/aur_bot_ed25519 -N ""
```

### Step 2: Add to AUR (1 minute)
```bash
# Copy public key
cat ~/.ssh/aur_bot_ed25519.pub

# Go to: https://aur.archlinux.org/account/
# Paste in "SSH Public Key" section
# Click "Update"
```

### Step 3: Add to GitHub (1 minute)
```bash
# Copy private key (entire output)
cat ~/.ssh/aur_bot_ed25519

# Go to: https://github.com/oxyzenQ/lyvoxa/settings/secrets/actions
# Click "New repository secret"
# Name: AUR_SSH_PRIVATE_KEY
# Value: [paste private key with BEGIN/END lines]
# Click "Add secret"
```

### ✅ Verify
```bash
# Test SSH
ssh -T -i ~/.ssh/aur_bot_ed25519 aur@aur.archlinux.org

# Expected: "Hi username! You've successfully authenticated..."
```

---

## 🎯 That's It!

Your workflow is already configured. Next time you:
1. Push a tag (e.g., `git tag v1.0.0 && git push origin v1.0.0`)
2. The `📦 AUR Sync` workflow automatically publishes to AUR

---

## 📖 Need Details?

See complete guide: [`docs/AUR_SSH_SETUP.md`](docs/AUR_SSH_SETUP.md)

---

## 🆘 Troubleshooting

### "Permission denied (publickey)"
- ❌ Public key not added to AUR account
- ✅ Add to: https://aur.archlinux.org/account/

### "SSH key might be in wrong format"
- ❌ Private key missing BEGIN/END lines
- ✅ Copy FULL key output (including `-----BEGIN OPENSSH PRIVATE KEY-----`)

### "Failed to clone AUR repository"
- ❌ Wrong package name or doesn't exist
- ✅ Create package first on AUR or check `AUR_REPO` in workflow

---

**Made with 🔥 by lyvoxa automation**
