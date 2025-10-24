# 🔑 AUR SSH Key Setup - Critical Steps

## ⚠️ Common Issue: "error in libcrypto"

If you see this error in GitHub Actions:
```
Load key "/home/runner/.ssh/aur": error in libcrypto
aur@aur.archlinux.org: Permission denied (publickey).
```

This means the SSH key in GitHub Secrets is **incorrectly formatted**.

---

## ✅ Correct Setup Process

### Step 1: Generate SSH Key

```bash
ssh-keygen -t ed25519 -f ~/.ssh/aur -C "AUR access for lyvoxa"
```

**Important**: 
- Don't use a passphrase (or GitHub Actions can't use it automatically)
- Or if you must use passphrase, you'll need ssh-agent setup

### Step 2: Add Public Key to AUR

```bash
# Display public key
cat ~/.ssh/aur.pub
```

Copy the **entire output** and add to:
1. Login to https://aur.archlinux.org
2. Go to **"My Account"**
3. Paste in **"SSH Public Key"** field
4. Click **"Update"**

### Step 3: Test SSH Connection

```bash
ssh -T aur@aur.archlinux.org
```

Expected output:
```
PTY allocation request failed on channel 0
```

This is **correct**! It means your key works.

### Step 4: Add Private Key to GitHub Secrets

**CRITICAL**: The secret must preserve exact formatting!

#### Method 1: Base64 Encoding (Recommended)

```bash
# Encode to base64 (preserves all formatting)
cat ~/.ssh/aur | base64 -w 0 > aur_key_base64.txt

# Show the encoded key
cat aur_key_base64.txt
```

**Then in GitHub:**
1. Go to repository → **Settings** → **Secrets and variables** → **Actions**
2. Click **"New repository secret"**
3. Name: `AUR_SSH_PRIVATE_KEY_BASE64`
4. Value: Paste the **entire** base64 string from `aur_key_base64.txt`
5. Click **"Add secret"**

**Update workflow** to decode:
```yaml
- name: Setup SSH for AUR
  env:
    AUR_SSH_PRIVATE_KEY_BASE64: ${{ secrets.AUR_SSH_PRIVATE_KEY_BASE64 }}
  run: |
    mkdir -p ~/.ssh
    echo "$AUR_SSH_PRIVATE_KEY_BASE64" | base64 -d > ~/.ssh/aur
    chmod 600 ~/.ssh/aur
    # ... rest of setup
```

#### Method 2: Direct Copy (Tricky)

```bash
# Display private key
cat ~/.ssh/aur
```

**Copy the ENTIRE output**, including:
- `-----BEGIN OPENSSH PRIVATE KEY-----`
- All the encoded content
- `-----END OPENSSH PRIVATE KEY-----`

**Important formatting rules:**
1. Include header and footer
2. Preserve all newlines
3. No extra spaces
4. No missing lines

**In GitHub:**
1. Settings → Secrets → Actions → New secret
2. Name: `AUR_SSH_PRIVATE_KEY`
3. Value: Paste the **entire** private key
4. Click **"Add secret"**

**Verification:**
The secret should look like this (in your clipboard before pasting):
```
-----BEGIN OPENSSH PRIVATE KEY-----
b3BlbnNzaC1rZXktdjEAAAAABG5vbmUAAAAEbm9uZQAAAAAAAAABAAAAMwAAAAtzc2gtZW
QyNTUxOQAAACDuZi5vH5JF3T7yrFT2dqJkpRRqNSvqvvxvx6NwYqvV9AAAAJh8jqwOfI6s
... (many more lines)
-----END OPENSSH PRIVATE KEY-----
```

---

## 🔍 Verify Secret is Correct

After adding the secret, you can verify it works by:

### Option 1: Manual Workflow Trigger

1. Go to **Actions** → **AUR Release**
2. Click **"Run workflow"**
3. Select **"main"** branch
4. Click **"Run workflow"**
5. Watch the log - SSH setup step should show:
   ```
   ✅ SSH configured successfully
   ```

### Option 2: Check Workflow Logs

If it fails, the logs will show:
```
❌ SSH key format is invalid!
Make sure AUR_SSH_PRIVATE_KEY secret contains the ENTIRE private key
```

---

## 🐛 Troubleshooting

### Error: "error in libcrypto"

**Cause**: SSH key is corrupted or missing newlines

**Solution**: Use base64 encoding method (Method 1 above)

### Error: "Permission denied (publickey)"

**Possible causes:**

1. **Public key not added to AUR**
   ```bash
   # Re-add public key to AUR account
   cat ~/.ssh/aur.pub
   ```

2. **Wrong key in secret**
   ```bash
   # Make sure you copied the PRIVATE key (not public)
   cat ~/.ssh/aur  # This is what goes in GitHub Secret
   ```

3. **Key has passphrase**
   ```bash
   # Remove passphrase:
   ssh-keygen -p -f ~/.ssh/aur
   # Enter old passphrase, then press Enter twice for no new passphrase
   ```

### Error: "Repository does not exist"

**Cause**: Package `lyvoxa-bin` hasn't been created on AUR yet

**Solution**: Create it manually first:
```bash
git clone ssh://aur@aur.archlinux.org/lyvoxa-bin.git
cd lyvoxa-bin
cp ../lyvoxa/lyvoxa-bin/PKGBUILD .
cp ../lyvoxa/lyvoxa-bin/.SRCINFO .
git add .
git commit -m "Initial commit: lyvoxa-bin"
git push
```

---

## ✅ Checklist

Before running workflow:

- [ ] SSH key generated (`~/.ssh/aur`)
- [ ] Public key added to AUR account
- [ ] SSH connection tested (`ssh -T aur@aur.archlinux.org`)
- [ ] Private key added to GitHub Secrets
- [ ] Secret format verified (use base64 if unsure)
- [ ] Package created on AUR (initial manual push)
- [ ] Workflow tested manually

---

## 📝 Quick Reference

### Generate Key
```bash
ssh-keygen -t ed25519 -f ~/.ssh/aur -N ""
```

### Show Public Key (for AUR)
```bash
cat ~/.ssh/aur.pub
```

### Show Private Key (for GitHub - Method 2)
```bash
cat ~/.ssh/aur
```

### Encode Private Key (for GitHub - Method 1, Recommended)
```bash
cat ~/.ssh/aur | base64 -w 0
```

### Test Connection
```bash
ssh -T aur@aur.archlinux.org
```

### Test Key Locally
```bash
ssh-keygen -y -f ~/.ssh/aur
# Should output public key without errors
```

---

## 🎯 Recommended Approach

For **maximum reliability**, use **base64 encoding**:

1. Generate key without passphrase
2. Add public key to AUR
3. Test SSH connection
4. **Encode private key to base64**
5. Add base64 string to GitHub Secret
6. Update workflow to decode it

This eliminates all newline/formatting issues!

---

## 🔐 Security Notes

**SSH Private Key Security:**
- ✅ GitHub encrypts secrets at rest
- ✅ Secrets are only exposed to your workflows
- ✅ Secrets are masked in logs
- ✅ Use SSH key only for AUR (dedicated key)
- ⚠️ Never commit private key to repo
- ⚠️ Don't share private key

**If Compromised:**
1. Delete key from AUR account immediately
2. Delete GitHub Secret
3. Generate new key
4. Repeat setup process

---

**Remember**: The SSH key format is critical. When in doubt, use base64 encoding! 🔑
