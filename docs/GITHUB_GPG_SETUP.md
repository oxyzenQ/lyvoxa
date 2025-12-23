# 🔐 Setup GPG Auto-Signature di GitHub Actions

Panduan lengkap step-by-step untuk mengaktifkan GPG auto-signing di GitHub Actions untuk Lyvoxa releases.

## 📋 Prerequisites

- ✅ GPG key sudah dibuat (`gpg --list-secret-keys`)
- ✅ Public key sudah di-upload ke keyserver
- ✅ Repository access (admin permissions)

## 🎯 Overview

Setelah setup, workflow akan otomatis:
1. Import GPG private key dari GitHub Secrets
2. Sign release package dengan GPG
3. Upload `.sig` file ke GitHub releases
4. User bisa verify authenticity

**Security:** Private key hanya live di GitHub Actions container, langsung dihapus setelah build.

---

## 📝 Step-by-Step Setup

### Step 1: Verify GPG Key Kamu

```bash
# List secret keys
gpg --list-secret-keys --keyid-format LONG

# Output example:
# sec   ed25519/0D8D13BB989AF9F0 2025-10-23 [SC]
#       3495ABF0957D28A7E8501375 0D8D13BB989AF9F0
# uid   [ultimate] Rezky Cahya Sahputra (Investor) <with.rezky@gmail.com>
# ssb   cv25519/XXXXXXXXXXXX 2025-10-23 [E]
```

**Catat Key ID kamu**: `0D8D13BB989AF9F0` (16 character)

### Step 2: Export Private Key

```bash
# Export private key dalam ASCII-armored format
gpg --armor --export-secret-keys 0D8D13BB989AF9F0 > lyvoxa-private-key.asc

# Check file created
ls -lh lyvoxa-private-key.asc

# View content (optional - untuk verify format)
cat lyvoxa-private-key.asc
```

**Output file akan berisi:**
```
-----BEGIN PGP PRIVATE KEY BLOCK-----

lQdGBGcY8w0BEADJvx+...
... (banyak baris base64) ...
-----END PGP PRIVATE KEY BLOCK-----
```

⚠️ **PENTING**: File ini sangat sensitif! Jangan commit ke git atau share.

### Step 3: Copy Private Key Content

```bash
# Copy ke clipboard (Linux dengan xclip)
cat lyvoxa-private-key.asc | xclip -selection clipboard

# Atau manual copy-paste
cat lyvoxa-private-key.asc
# Lalu select all dan copy (Ctrl+Shift+C)
```

**Pastikan termasuk**:
- `-----BEGIN PGP PRIVATE KEY BLOCK-----`
- Semua baris content
- `-----END PGP PRIVATE KEY BLOCK-----`

### Step 4: Setup GitHub Secret - GPG_PRIVATE_KEY

1. **Buka GitHub repository**: `https://github.com/oxyzenQ/lyvoxa`

2. **Navigate to Secrets**:
   ```
   Settings → Secrets and variables → Actions → New repository secret
   ```

3. **Create Secret**:
   - **Name**: `GPG_PRIVATE_KEY`
   - **Secret**: Paste seluruh content dari `lyvoxa-private-key.asc`
   - Click **Add secret**

   ![Screenshot placeholder for adding secret]

4. **Verify**: Kamu akan lihat `GPG_PRIVATE_KEY` di list secrets (value hidden)

### Step 5: Setup GitHub Secret - GPG_PASSPHRASE

1. **Create another secret**:
   ```
   Settings → Secrets and variables → Actions → New repository secret
   ```

2. **Fill details**:
   - **Name**: `GPG_PASSPHRASE`
   - **Secret**: Masukkan passphrase GPG key kamu (yang dipakai waktu buat key)
   - Click **Add secret**

⚠️ **Kalau key kamu tidak pakai passphrase**, skip step ini (workflow tetap jalan).

### Step 6: Verify Secrets Created

Di halaman Secrets, kamu harus lihat:
```
✅ GPG_PRIVATE_KEY      Updated X seconds ago
✅ GPG_PASSPHRASE       Updated X seconds ago
```

### Step 7: Upload Public Key ke Keyserver

Agar user bisa verify signature:

```bash
# Upload ke OpenPGP keyserver
gpg --keyserver hkps://keys.openpgp.org --send-keys 0D8D13BB989AF9F0

# Output:
# gpg: sending key 0D8D13BB989AF9F0 to hkps://keys.openpgp.org
```

**Verify upload berhasil:**
```bash
# Test import dari keyserver (pakai incognito mode / key lain)
gpg --keyserver hkps://keys.openpgp.org --recv-keys 0D8D13BB989AF9F0

# Output kalau berhasil:
# gpg: key 0D8D13BB989AF9F0: public key "Rezky Cahya Sahputra..." imported
```

### Step 8: Cleanup Local Files

```bash
# HAPUS private key file dari local!
shred -vfz -n 10 lyvoxa-private-key.asc

# Atau kalau tidak ada shred:
rm -f lyvoxa-private-key.asc

# Clear bash history (optional)
history -c
```

⚠️ **PENTING**: Private key sudah tersimpan aman di GitHub Secrets, hapus dari local!

### Step 9: Test Auto-Signing

Trigger release untuk test:

```bash
# Create and push tag
git tag -a 3.0.1 -m "Test GPG signing"
git push origin 3.0.1

# Atau manual trigger di GitHub:
# Actions → 🌟 Release → Run workflow → Input version: 3.0.1
```

**Monitor workflow logs**:
```
https://github.com/oxyzenQ/lyvoxa/actions/workflows/release.yml
```

**Expected logs:**
```
🔐 Setting up GPG for signing...
✅ GPG key imported
gpg: key 0D8D13BB989AF9F0: secret key imported

🔏 Signing package with GPG...
✅ Signature created: lyvoxa-3.1.2-linux-amd64.tar.gz.sig (1.0K)
gpg: Good signature from "Rezky Cahya Sahputra (Investor) <with.rezky@gmail.com>"

📦 Package: lyvoxa-3.1.2-linux-amd64.tar.gz
🔐 Checksum: lyvoxa-3.1.2-linux-amd64.tar.gz.sha256
🔏 Signature: lyvoxa-3.1.2-linux-amd64.tar.gz.sig
```

### Step 10: Verify Release Assets

Check release page:
```
https://github.com/oxyzenQ/lyvoxa/releases/tag/3.0.1
```

**Expected assets:**
```
✅ lyvoxa-3.1.2-linux-amd64.tar.gz          (binary package)
✅ lyvoxa-3.1.2-linux-amd64.tar.gz.sha256   (checksum)
✅ lyvoxa-3.1.2-linux-amd64.tar.gz.sig      (GPG signature) ← NEW!
✅ Source code (zip)
✅ Source code (tar.gz)
```

### Step 11: Test User Verification

Simulate user verifying download:

```bash
# Download files
wget https://github.com/oxyzenQ/lyvoxa/releases/download/3.1.2/lyvoxa-3.1.2-linux-amd64.tar.gz
wget https://github.com/oxyzenQ/lyvoxa/releases/download/3.1.2/lyvoxa-3.1.2-linux-amd64.tar.gz.sig

# Import public key
gpg --keyserver hkps://keys.openpgp.org --recv-keys 0D8D13BB989AF9F0

# Verify signature
gpg --verify lyvoxa-3.1.2-linux-amd64.tar.gz.sig lyvoxa-3.1.2-linux-amd64.tar.gz

# Expected output:
# gpg: Signature made [date]
# gpg:                using EDDSA key 0D8D13BB989AF9F0
# gpg: Good signature from "Rezky Cahya Sahputra (Investor) <with.rezky@gmail.com>"
```

✅ Kalau ada **"Good signature"** = SUCCESS!

---

## 🔍 Troubleshooting

### Issue 1: "no secret key" in workflow logs

**Cause**: `GPG_PRIVATE_KEY` secret tidak set atau salah format

**Fix**:
1. Verify secret di GitHub Settings
2. Re-export private key: `gpg --armor --export-secret-keys 0D8D13BB989AF9F0`
3. Paste **full content** including `-----BEGIN/END-----`
4. Delete dan re-create secret

### Issue 2: "signing failed: Inappropriate ioctl for device"

**Cause**: Passphrase handling issue

**Fix**: Sudah handled di workflow dengan `--pinentry-mode loopback`

Check workflow has:
```yaml
--pinentry-mode loopback --detach-sign
```

### Issue 3: No .sig file in release

**Cause**: Workflow step failed atau skipped

**Check**:
1. Workflow logs untuk error di step "Sign Package (GPG)"
2. Verify both secrets exist
3. Check `continue-on-error: true` tidak menyembunyikan error

### Issue 4: "Bad signature" waktu user verify

**Cause**: File dimodifikasi atau signature tidak match

**Fix**:
1. Download ulang file (jangan pakai cache)
2. Verify checksum dulu: `sha256sum -c file.sha256`
3. Kalau checksum OK tapi signature BAD = workflow issue

### Issue 5: Key not found on keyserver

**Cause**: Public key belum di-upload

**Fix**:
```bash
# Upload ulang
gpg --keyserver hkps://keys.openpgp.org --send-keys 0D8D13BB989AF9F0

# Verify
gpg --keyserver hkps://keys.openpgp.org --recv-keys 0D8D13BB989AF9F0
```

---

## 🛡️ Security Best Practices

### ✅ Do's

1. **Rotate keys yearly**: Set expiration dan renew
   ```bash
   gpg --edit-key 0D8D13BB989AF9F0
   > expire
   > 1y  (1 year)
   > save
   ```

2. **Backup private key**: Simpan offline di USB/hardware
   ```bash
   gpg --armor --export-secret-keys 0D8D13BB989AF9F0 > backup.asc
   # Store in safe place, encrypt USB
   ```

3. **Use subkey**: Buat subkey khusus untuk signing (advanced)
   ```bash
   gpg --edit-key 0D8D13BB989AF9F0
   > addkey
   > 4  (RSA sign only)
   > save
   ```

4. **Monitor workflow logs**: Check setiap release ada .sig

5. **Test verification regularly**: Ensure user experience OK

### ❌ Don'ts

1. ❌ **Never commit** private key ke git
2. ❌ **Never share** passphrase via email/chat
3. ❌ **Never use** master key directly (use subkey)
4. ❌ **Never skip** key backup
5. ❌ **Never hardcode** secrets dalam workflow

---

## 📊 Workflow Behavior

### With GPG Secrets Configured

```yaml
✅ Import GPG key from secrets
✅ Sign package → generate .sig file
✅ Upload .sig to release
✅ Release notes include GPG verification instructions
```

### Without GPG Secrets (Fallback)

```yaml
⚠️ GPG steps skipped (continue-on-error: true)
✅ Release still works (only SHA256)
✅ No .sig file generated
✅ Workflow does not fail
```

**This ensures**: Release workflow always succeeds, GPG signing is optional enhancement.

---

## 🔑 Key Information Summary

**Your Key Details:**
- **Key ID**: `0D8D13BB989AF9F0`
- **Key Type**: `ed25519` (modern, secure)
- **Name**: Rezky Cahya Sahputra (Investor)
- **Email**: with.rezky@gmail.com
- **Keyserver**: hkps://keys.openpgp.org

**GitHub Secrets Required:**
```
GPG_PRIVATE_KEY       = ASCII-armored private key (with -----BEGIN/END-----)
GPG_PASSPHRASE        = Your GPG key passphrase (optional if no passphrase)
```

**Workflow Files:**
- `.github/workflows/release.yml` - Main release workflow with GPG steps
- `docs/GPG_SIGNING.md` - Developer guide
- `docs/VERIFICATION.md` - User guide (Bahasa Indonesia)

---

## 📚 Additional Resources

- **OpenPGP Best Practices**: https://riseup.net/en/security/message-security/openpgp/best-practices
- **GitHub Encrypted Secrets**: https://docs.github.com/en/actions/security-guides/encrypted-secrets
- **GnuPG Manual**: https://www.gnupg.org/gph/en/manual.html
- **Keyserver Info**: https://keys.openpgp.org/about/usage

---

## ✅ Quick Checklist

Before completing setup, verify:

- [ ] GPG key created and listed in `gpg --list-secret-keys`
- [ ] Private key exported to ASCII-armored format
- [ ] `GPG_PRIVATE_KEY` secret added to GitHub
- [ ] `GPG_PASSPHRASE` secret added (if key has passphrase)
- [ ] Public key uploaded to keyserver
- [ ] Private key file deleted from local machine
- [ ] Test release triggered (tag push or manual)
- [ ] Workflow logs show "✅ Signature created"
- [ ] Release assets include `.sig` file
- [ ] User verification test passed (Good signature)

---

**🎉 Setup Complete!**

Setiap release sekarang akan otomatis:
1. ✅ Build optimized binary
2. ✅ Generate SHA256 checksum
3. ✅ Sign dengan GPG (auto)
4. ✅ Upload .tar.gz + .sha256 + .sig
5. ✅ Users dapat verify authenticity

**Professional release workflow dengan cryptographic verification!** 🔐

---

**Questions?** Open issue di: https://github.com/oxyzenQ/lyvoxa/issues
