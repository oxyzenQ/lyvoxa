# 🔑 SSH Signing Setup Guide

## Overview

This guide explains how to set up SSH key signing for Lyvoxa releases. SSH signing provides cryptographic proof that releases come from the official maintainer.

## 🛠️ Prerequisites

- GitHub repository with Actions enabled
- SSH key pair (Ed25519 recommended)
- Repository admin access for Secrets management

## 📋 Setup Steps

### 1. Generate SSH Key for Signing (if needed)

```bash
# Generate new Ed25519 key for signing
ssh-keygen -t ed25519 -C "lyvoxa-signing-key" -f ~/.ssh/lyvoxa_signing_key

# This creates:
# ~/.ssh/lyvoxa_signing_key (private key)
# ~/.ssh/lyvoxa_signing_key.pub (public key)
```

### 2. Add Public Key to GitHub Profile

```bash
# Display public key
cat ~/.ssh/lyvoxa_signing_key.pub

# Copy the output and add to GitHub:
# 1. Go to GitHub Settings → SSH and GPG keys
# 2. Click "New SSH key"
# 3. Paste the public key
# 4. Save
```

### 3. Add Private Key to GitHub Secrets

```bash
# Display private key (KEEP THIS SECURE!)
cat ~/.ssh/lyvoxa_signing_key

# Add to GitHub Secrets:
# 1. Go to Repository → Settings → Secrets and variables → Actions
# 2. Click "New repository secret"
# 3. Name: SSH_SIGN_KEY
# 4. Value: Paste the ENTIRE private key (including headers)
# 5. Click "Add secret"
```

### 4. Optional: Add HMAC Secret Key

```bash
# Generate random HMAC key
openssl rand -hex 32

# Add to GitHub Secrets:
# 1. Name: HMAC_SECRET_KEY
# 2. Value: Paste the generated hex string
```

## 🔐 Security Best Practices

### Key Management

1. **Dedicated Signing Key**: Use separate key only for signing
2. **Strong Passphrase**: Protect private key with strong passphrase
3. **Secure Storage**: Store private key securely, never commit to repo
4. **Key Rotation**: Rotate signing keys periodically (annually recommended)

### GitHub Secrets Security

1. **Minimal Access**: Only add secrets to repositories that need them
2. **Audit Access**: Regularly review who has access to repository secrets
3. **Environment Separation**: Use different keys for different environments
4. **Monitoring**: Monitor secret usage in Actions logs

## 🧪 Testing the Setup

### 1. Create Test Release

```bash
# Tag a test release
git tag -a test-stellar-2.0 -m "Test release for SSH signing"
git push origin test-stellar-2.0
```

### 2. Verify Workflow Execution

1. Go to GitHub Actions tab
2. Check "🌟 Stellar Release" workflow
3. Verify all steps complete successfully
4. Check release artifacts include `.sig` files

### 3. Manual Verification Test

```bash
# Download test release files
wget https://github.com/oxyzenQ/lyvoxa/releases/download/test-stellar-2.0/lyvoxa-test-stellar-2.0-linux-x86_64.tar.gz
wget https://github.com/oxyzenQ/lyvoxa/releases/download/test-stellar-2.0/lyvoxa-test-stellar-2.0-linux-x86_64.tar.gz.sig

# Get public key
curl -s https://github.com/oxyzenQ.keys > oxyzenQ.pub

# Verify signature
ssh-keygen -Y verify -f oxyzenQ.pub -I file -n file \
  -s lyvoxa-test-stellar-2.0-linux-x86_64.tar.gz.sig \
  < lyvoxa-test-stellar-2.0-linux-x86_64.tar.gz
```

## 🚨 Troubleshooting

### Common Issues

#### "SSH_SIGN_KEY not found in secrets"
- **Solution**: Ensure secret is named exactly `SSH_SIGN_KEY`
- **Check**: Repository → Settings → Secrets and variables → Actions

#### "ssh-keygen: command not found"
- **Solution**: GitHub Actions runners include OpenSSH by default
- **Check**: Verify workflow is running on `ubuntu-latest`

#### "Bad signature" error
- **Solution**: Verify private/public key pair match
- **Check**: Regenerate key pair if necessary

#### Permission denied errors
- **Solution**: Check private key format and permissions
- **Check**: Ensure entire private key is copied including headers

### Debug Steps

1. **Check Workflow Logs**: Review GitHub Actions logs for detailed error messages
2. **Verify Key Format**: Ensure private key includes `-----BEGIN` and `-----END` lines
3. **Test Locally**: Test signing process on local machine first
4. **Key Validation**: Verify public key is correctly added to GitHub profile

## 📚 Additional Resources

- [SSH Signature Documentation](https://man.openbsd.org/ssh-keygen.1#Y)
- [GitHub Secrets Documentation](https://docs.github.com/en/actions/security-guides/encrypted-secrets)
- [OpenSSH Key Management](https://www.openssh.com/manual.html)

## 🔄 Key Rotation Process

### When to Rotate

- **Annually**: Regular rotation schedule
- **Compromise**: If key is potentially compromised
- **Personnel Changes**: When maintainer access changes
- **Security Upgrade**: When upgrading to newer key algorithms

### Rotation Steps

1. **Generate New Key**: Create new SSH key pair
2. **Update GitHub Profile**: Add new public key
3. **Update Secrets**: Replace `SSH_SIGN_KEY` with new private key
4. **Test Release**: Verify new key works with test release
5. **Revoke Old Key**: Remove old public key from GitHub profile
6. **Update Documentation**: Update any references to old key fingerprint

---

**Maintained by**: rezky_nightky | **Last Updated**: 2025-01-24 | **Security Level**: Enterprise Grade
