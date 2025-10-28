# 🔐 Verifikasi Download Lyvoxa

Panduan untuk memverifikasi keaslian dan integritas file download Lyvoxa.

## 📥 Download File Release

```bash
# Download binary package
wget https://github.com/oxyzenQ/lyvoxa/releases/download/3.0/lyvoxa-3.1-linux-amd64.tar.gz

# Download checksum
wget https://github.com/oxyzenQ/lyvoxa/releases/download/3.0/lyvoxa-3.1-linux-amd64.tar.gz.sha256

# Download GPG signature (optional)
wget https://github.com/oxyzenQ/lyvoxa/releases/download/3.0/lyvoxa-3.1-linux-amd64.tar.gz.sig
```

## ✅ Verifikasi SHA256 (Wajib)

Verifikasi checksum untuk memastikan file tidak corrupt/rusak:

```bash
sha256sum -c lyvoxa-3.1-linux-amd64.tar.gz.sha256
```

**Output yang benar:**
```
lyvoxa-3.1-linux-amd64.tar.gz: OK
```

**Output salah (file corrupt/tampered):**
```
lyvoxa-3.1-linux-amd64.tar.gz: FAILED
sha256sum: WARNING: 1 computed checksum did NOT match
```

❌ **JANGAN install jika checksum FAILED!** File mungkin corrupt atau sudah dimodifikasi.

## 🔏 Verifikasi GPG (Opsional, Recommended)

Verifikasi signature untuk memastikan file benar-benar dari developer resmi:

### Step 1: Import Public Key (Sekali aja)

```bash
# Import key dari OpenPGP keyserver
gpg --keyserver hkps://keys.openpgp.org --recv-keys 0D8D13BB989AF9F0
```

**Output:**
```
gpg: key 0D8D13BB989AF9F0: "Rezky Cahya Sahputra (Investor) <with.rezky@gmail.com>" imported
gpg: Total number processed: 1
gpg:               imported: 1
```

**Atau dari keyserver lain:**
```bash
# Ubuntu keyserver
gpg --keyserver hkps://keyserver.ubuntu.com --recv-keys 0D8D13BB989AF9F0

# GnuPG keyserver
gpg --keyserver hkps://keys.gnupg.net --recv-keys 0D8D13BB989AF9F0
```

### Step 2: Verify Signature

```bash
gpg --verify lyvoxa-3.1-linux-amd64.tar.gz.sig lyvoxa-3.1-linux-amd64.tar.gz
```

**Output yang benar:**
```
gpg: Signature made Thu Oct 24 11:00:00 2025 WIB
gpg:                using RSA key 0D8D13BB989AF9F0
gpg: Good signature from "Rezky Cahya Sahputra (Investor) <with.rezky@gmail.com>" [unknown]
gpg: WARNING: This key is not certified with a trusted signature!
gpg:          There is no indication that the signature belongs to the owner.
Primary key fingerprint: XXXX XXXX XXXX XXXX XXXX  XXXX XXXX XXXX XXXX XXXX
```

✅ **"Good signature"** = File asli dari developer!

⚠️ Warning tentang "not certified" adalah normal kalau kamu belum trust key-nya. Yang penting ada **"Good signature"**.

**Output salah (file sudah dimodifikasi):**
```
gpg: BAD signature from "Rezky Cahya Sahputra (Investor) <with.rezky@gmail.com>"
```

❌ **JANGAN install jika BAD signature!** File sudah dimodifikasi oleh pihak tidak bertanggung jawab.

### Step 3: Trust Key (Optional)

Kalau kamu mau hilangkan warning "not certified":

```bash
# Edit trust level
gpg --edit-key 0D8D13BB989AF9F0

# Di prompt GPG, ketik:
> trust
> 5  (I trust ultimately)
> y   (yes)
> quit
```

## 📋 Full Verification Script

Script lengkap untuk download + verify:

```bash
#!/bin/bash
VERSION="3.0"
ARTIFACT="lyvoxa-${VERSION}-linux-amd64"
BASE_URL="https://github.com/oxyzenQ/lyvoxa/releases/download/${VERSION}"

echo "📥 Downloading Lyvoxa ${VERSION}..."
wget -q "${BASE_URL}/${ARTIFACT}.tar.gz"
wget -q "${BASE_URL}/${ARTIFACT}.tar.gz.sha256"
wget -q "${BASE_URL}/${ARTIFACT}.tar.gz.sig"

echo "🔐 Verifying SHA256 checksum..."
if sha256sum -c "${ARTIFACT}.tar.gz.sha256"; then
    echo "✅ Checksum valid"
else
    echo "❌ Checksum FAILED - DO NOT INSTALL!"
    exit 1
fi

echo "🔏 Importing GPG key..."
gpg --keyserver hkps://keys.openpgp.org --recv-keys 0D8D13BB989AF9F0 2>/dev/null

echo "🔏 Verifying GPG signature..."
if gpg --verify "${ARTIFACT}.tar.gz.sig" "${ARTIFACT}.tar.gz" 2>&1 | grep -q "Good signature"; then
    echo "✅ Signature valid"
else
    echo "❌ Signature FAILED - DO NOT INSTALL!"
    exit 1
fi

echo "✅ All verifications passed!"
echo "📦 Extracting..."
tar -xzf "${ARTIFACT}.tar.gz"

echo "🚀 Installing..."
sudo cp "${ARTIFACT}/bin/lyvoxa" /usr/local/bin/
chmod +x /usr/local/bin/lyvoxa

echo "✅ Lyvoxa ${VERSION} installed successfully!"
lyvoxa --version
```

Save script sebagai `install-lyvoxa.sh` dan jalankan:

```bash
chmod +x install-lyvoxa.sh
./install-lyvoxa.sh
```

## 🔑 Developer's Public Key Info

**Key ID:** `0D8D13BB989AF9F0`  
**Name:** Rezky Cahya Sahputra (Investor)  
**Email:** with.rezky@gmail.com  
**Type:** RSA  
**Keyservers:**
- hkps://keys.openpgp.org (primary)
- hkps://keyserver.ubuntu.com
- hkps://keys.gnupg.net

**View full fingerprint:**
```bash
gpg --fingerprint 0D8D13BB989AF9F0
```

## ❓ FAQ

### Q: Apa bedanya SHA256 dan GPG?

**SHA256 Checksum:**
- ✅ Cek integritas file (tidak corrupt)
- ❌ Tidak cek keaslian (dari siapa)
- 🎯 Use case: Pastikan download tidak error

**GPG Signature:**
- ✅ Cek keaslian (benar dari developer)
- ✅ Cek integritas (bonus)
- 🎯 Use case: Pastikan file tidak fake/trojan

**Recommendation:** Gunakan KEDUANYA untuk keamanan maksimal!

### Q: Apa itu format .sig?

`.sig` adalah GPG signature dalam binary format:
- Lebih kecil dari `.asc` (ASCII-armored)
- Format standar di Arch Linux (pacman)
- Lebih cepat generate dan verify

### Q: Gimana kalau GPG bilang "no public key"?

Import public key dulu:
```bash
gpg --keyserver hkps://keys.openpgp.org --recv-keys 0D8D13BB989AF9F0
```

### Q: Apa warning "This key is not certified" bahaya?

Tidak bahaya! Itu cuma warning standar GPG kalau kamu belum explicitly trust key tersebut. Yang penting adalah **"Good signature"**.

Kalau mau hilangkan warning, jalankan:
```bash
gpg --edit-key 0D8D13BB989AF9F0
> trust
> 5
> quit
```

### Q: Gimana kalau download dari mirror/CDN bukan GitHub?

Tetap verify dengan SHA256 dan GPG! Checksum/signature harus match dengan file asli di GitHub releases.

### Q: Bisa verify tanpa internet?

- **SHA256:** ✅ Bisa offline (cukup punya .sha256 file)
- **GPG:** ⚠️ Perlu import key sekali (online), setelah itu bisa offline

## 🛡️ Security Best Practices

1. ✅ **Selalu verify SHA256** sebelum extract
2. ✅ **Verify GPG signature** untuk keamanan extra
3. ✅ **Download dari GitHub releases** (official source)
4. ❌ **Jangan skip verification** "ah males verify"
5. ❌ **Jangan trust file** dengan BAD signature
6. ❌ **Jangan download** dari source tidak jelas

## 📞 Contact

Kalau ada pertanyaan atau menemukan masalah verifikasi:

- **Issues:** https://github.com/oxyzenQ/lyvoxa/issues
- **Email:** with.rezky@gmail.com
- **GPG Key:** 0D8D13BB989AF9F0

---

**Stay safe and verify your downloads!** 🔐
