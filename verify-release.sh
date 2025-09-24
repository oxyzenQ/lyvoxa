#!/bin/bash
# Lyvoxa Professional Package Verification Script
# Usage: ./verify-release.sh v1.5.7

set -e

VERSION=${1:-v1.5.7}
BASE_URL="https://github.com/oxyzenQ/lyvoxa/releases/download/$VERSION"

echo "🔐 Lyvoxa Release Verification - $VERSION"
echo "=========================================="

# Create temp directory
TMP_DIR=$(mktemp -d)
cd "$TMP_DIR"
echo "📁 Working in: $TMP_DIR"
echo

# Download packages and verification files
echo "📥 Downloading packages and verification files..."

# Universal package
echo "  → Universal package (.tar.gz)"
curl -fsSL -o "lyvoxa-$VERSION-linux-x86_64.tar.gz" "$BASE_URL/lyvoxa-$VERSION-linux-x86_64.tar.gz"
curl -fsSL -o "lyvoxa-$VERSION-linux-x86_64.tar.gz.sha512" "$BASE_URL/lyvoxa-$VERSION-linux-x86_64.tar.gz.sha512" || echo "    ⚠️  SHA512 not found"
curl -fsSL -o "lyvoxa-$VERSION-linux-x86_64.tar.gz.sha256" "$BASE_URL/lyvoxa-$VERSION-linux-x86_64.tar.gz.sha256" || echo "    ⚠️  SHA256 not found"
curl -fsSL -o "lyvoxa-$VERSION-linux-x86_64.tar.gz.sig" "$BASE_URL/lyvoxa-$VERSION-linux-x86_64.tar.gz.sig" || echo "    ⚠️  Signature not found"

# Debian package
echo "  → Debian package (.deb)"
curl -fsSL -o "lyvoxa_$VERSION-1_amd64.deb" "$BASE_URL/lyvoxa_$VERSION-1_amd64.deb" || echo "    ⚠️  .deb not found"
curl -fsSL -o "lyvoxa_$VERSION-1_amd64.deb.sha256" "$BASE_URL/lyvoxa_$VERSION-1_amd64.deb.sha256" || echo "    ⚠️  .deb SHA256 not found"
curl -fsSL -o "lyvoxa_$VERSION-1_amd64.deb.sig" "$BASE_URL/lyvoxa_$VERSION-1_amd64.deb.sig" || echo "    ⚠️  .deb signature not found"

# Arch package
echo "  → Arch package (.zst)"  
curl -fsSL -o "lyvoxa-$VERSION-linux-x86_64.tar.zst" "$BASE_URL/lyvoxa-$VERSION-linux-x86_64.tar.zst" || echo "    ⚠️  .zst not found"
curl -fsSL -o "lyvoxa-$VERSION-linux-x86_64.tar.zst.sha512" "$BASE_URL/lyvoxa-$VERSION-linux-x86_64.tar.zst.sha512" || echo "    ⚠️  .zst SHA512 not found"
curl -fsSL -o "lyvoxa-$VERSION-linux-x86_64.tar.zst.sig" "$BASE_URL/lyvoxa-$VERSION-linux-x86_64.tar.zst.sig" || echo "    ⚠️  .zst signature not found"

# Unified files
echo "  → Unified verification files"
curl -fsSL -o "lyvoxa-$VERSION.checksums" "$BASE_URL/lyvoxa-$VERSION.checksums" || echo "    ⚠️  Unified checksums not found"
curl -fsSL -o "lyvoxa-$VERSION.sig.info" "$BASE_URL/lyvoxa-$VERSION.sig.info" || echo "    ⚠️  Signature info not found"

echo "✅ Download complete"
echo

# Verify checksums
echo "🔍 Verifying checksums..."

# SHA512 verification (universal + .zst)
for file in lyvoxa-$VERSION-linux-x86_64.tar.gz lyvoxa-$VERSION-linux-x86_64.tar.zst; do
  if [ -f "$file.sha512" ]; then
    echo "  → Verifying SHA512: $file"
    if sha512sum -c "$file.sha512"; then
      echo "    ✅ SHA512 verified"
    else
      echo "    ❌ SHA512 failed"
    fi
  fi
done

# SHA256 verification (universal + .deb)  
for file in lyvoxa-$VERSION-linux-x86_64.tar.gz lyvoxa_$VERSION-1_amd64.deb; do
  if [ -f "$file.sha256" ]; then
    echo "  → Verifying SHA256: $file"  
    if sha256sum -c "$file.sha256"; then
      echo "    ✅ SHA256 verified"
    else
      echo "    ❌ SHA256 failed"  
    fi
  fi
done

echo

# SSH signature verification
echo "🔑 Verifying SSH signatures..."
curl -fsSL https://github.com/oxyzenQ.keys > oxyzenQ.pub

for package in lyvoxa-$VERSION-linux-x86_64.tar.gz lyvoxa_$VERSION-1_amd64.deb lyvoxa-$VERSION-linux-x86_64.tar.zst; do
  if [ -f "$package.sig" ] && [ -f "$package" ]; then
    echo "  → Verifying signature: $package"
    if ssh-keygen -Y verify -f oxyzenQ.pub -I file -n file -s "$package.sig" < "$package" 2>/dev/null; then
      echo "    ✅ SSH signature verified"
    else
      echo "    ❌ SSH signature failed"
      echo "    📋 Signature file exists: $(ls -la "$package.sig" 2>/dev/null || echo "No")"
      echo "    📋 Package file exists: $(ls -la "$package" 2>/dev/null || echo "No")"
      echo "    📋 Public key: $(wc -l oxyzenQ.pub) lines"
    fi
  else
    echo "    ⚠️  Missing signature or package for: $package"
  fi
done

echo
echo "📋 File Summary:"
ls -la

# Cleanup
echo
echo "🧹 Cleaning up..."
cd /
rm -rf "$TMP_DIR"
echo "✅ Verification complete!"
