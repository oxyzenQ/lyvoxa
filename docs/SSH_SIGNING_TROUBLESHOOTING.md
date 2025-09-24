# 🔧 SSH Signing Troubleshooting

Common issues and solutions for SSH signing in GitHub Actions releases.

## 🚨 Common Errors

### Error: "No private key found"

**Symptoms:**
```
No private key found for "/home/runner/.ssh/id_ed25519"
Error: Process completed with exit code 255.
```

**Causes & Solutions:**

#### 1. Incorrect SSH Key Format
**Problem**: SSH key in GitHub Secrets has wrong format or missing newlines.

**Solution**: Ensure your SSH private key is in proper OpenSSH format:
```bash
# Correct format should start with:
-----BEGIN OPENSSH PRIVATE KEY-----
# And end with:
-----END OPENSSH PRIVATE KEY-----
```

#### 2. Missing Newlines in GitHub Secrets
**Problem**: GitHub Secrets sometimes strips newlines from multi-line values.

**Solutions**:

**Option A: Use Raw Key (Recommended)**
1. Copy the entire private key including headers
2. Paste directly into GitHub Secrets
3. Ensure no extra spaces or characters

**Option B: Base64 Encode**
```bash
# Encode your private key
base64 -w 0 ~/.ssh/id_ed25519

# Add the base64 string to GitHub Secrets
# The workflow will decode it automatically
```

#### 3. Wrong Key Type
**Problem**: Using RSA or other key types instead of ED25519.

**Solution**: Generate ED25519 key:
```bash
ssh-keygen -t ed25519 -C "lyvoxa-release-signing" -f ~/.ssh/id_ed25519 -N ""
```

## 🛠️ Setup Instructions

### Step 1: Generate SSH Key
```bash
# Run the setup helper
./scripts/setup-ssh-signing.sh

# Or manually:
ssh-keygen -t ed25519 -C "lyvoxa-release-signing" -f ~/.ssh/id_ed25519 -N ""
```

### Step 2: Add Public Key to GitHub
1. Copy the public key:
   ```bash
   cat ~/.ssh/id_ed25519.pub
   ```
2. Go to [GitHub SSH Keys](https://github.com/settings/keys)
3. Click "New SSH key"
4. Paste the public key

### Step 3: Add Private Key to Repository Secrets
1. Copy the private key:
   ```bash
   cat ~/.ssh/id_ed25519
   ```
2. Go to [Repository Secrets](https://github.com/oxyzenQ/lyvoxa/settings/secrets/actions)
3. Click "New repository secret"
4. Name: `SSH_SIGN_KEY`
5. Value: Paste the entire private key (including headers)

### Step 4: Test the Setup
```bash
# Create test tag
git tag -a test-signing -m "Test SSH signing"
git push origin test-signing

# Check the release workflow logs
```

## 🔍 Verification

### Local Testing
```bash
# Test signing locally
echo "test content" > test.txt
ssh-keygen -Y sign -f ~/.ssh/id_ed25519 -n file test.txt

# Test verification
curl -s https://github.com/oxyzenQ.keys > oxyzenQ.pub
ssh-keygen -Y verify -f oxyzenQ.pub -I file -n file -s test.txt.sig < test.txt
```

### GitHub Actions Testing
1. Check workflow logs for SSH key validation
2. Look for "✅ SSH key loaded and validated" message
3. Verify signature files are created in release assets

## 🐛 Debugging Steps

### 1. Check SSH Key Format
```bash
# Validate key format locally
ssh-keygen -l -f ~/.ssh/id_ed25519

# Should output something like:
# 256 SHA256:... your-email (ED25519)
```

### 2. Check GitHub Secrets
- Ensure secret name is exactly `SSH_SIGN_KEY`
- Verify no extra spaces or characters
- Check that the key includes headers and footers

### 3. Check Workflow Logs
Look for these messages in the release workflow:
- ✅ SSH key loaded and validated
- 🔑 Signing package with SSH key...
- ✅ SSH signature created!

### 4. Manual Verification
After a successful release, verify the signature:
```bash
# Download release files
wget https://github.com/oxyzenQ/lyvoxa/releases/download/stellar-1.5/lyvoxa-stellar-1.5-linux-x86_64.tar.gz
wget https://github.com/oxyzenQ/lyvoxa/releases/download/stellar-1.5/lyvoxa-stellar-1.5-linux-x86_64.tar.gz.sig

# Get public key
curl -s https://github.com/oxyzenQ.keys > oxyzenQ.pub

# Verify signature
ssh-keygen -Y verify -f oxyzenQ.pub -I file -n file \
  -s lyvoxa-stellar-1.5-linux-x86_64.tar.gz.sig \
  < lyvoxa-stellar-1.5-linux-x86_64.tar.gz
```

## 📋 Checklist

Before creating a release, ensure:

- [ ] SSH key is ED25519 format
- [ ] Public key is added to GitHub account
- [ ] Private key is in repository secrets as `SSH_SIGN_KEY`
- [ ] Key format includes proper headers/footers
- [ ] No extra spaces or characters in the secret
- [ ] Local signing test works
- [ ] Previous test release succeeded

## 🔧 Alternative Solutions

### Option 1: Regenerate Everything
```bash
# Remove old keys
rm -f ~/.ssh/id_ed25519*

# Generate new key
ssh-keygen -t ed25519 -C "lyvoxa-$(date +%Y%m%d)" -f ~/.ssh/id_ed25519 -N ""

# Follow setup steps again
```

### Option 2: Use Different Key Name
If you have conflicts with existing keys:
```bash
# Generate with different name
ssh-keygen -t ed25519 -C "lyvoxa-release" -f ~/.ssh/lyvoxa_signing -N ""

# Update workflow to use different path
# (requires workflow modification)
```

### Option 3: Skip Signing Temporarily
If urgent release is needed:
```bash
# Comment out SSH signing section in release.yml
# Or set SSH_SIGN_KEY secret to empty value
```

## 📞 Getting Help

If issues persist:

1. Check [GitHub Actions logs](https://github.com/oxyzenQ/lyvoxa/actions)
2. Verify SSH key with `ssh-keygen -l -f ~/.ssh/id_ed25519`
3. Test local signing with the troubleshooting commands above
4. Ensure GitHub account has the public key added

---

**Maintained by**: rezky_nightky | **Last Updated**: 2025-01-24 | **Version**: Stellar 1.5
