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

# Debian package
echo "  → Debian package (.deb)"
curl -fsSL -o "lyvoxa_$VERSION-1_amd64.deb" "$BASE_URL/lyvoxa_$VERSION-1_amd64.deb" || echo "    ⚠️  .deb not found"
curl -fsSL -o "lyvoxa_$VERSION-1_amd64.deb.sha512" "$BASE_URL/lyvoxa_$VERSION-1_amd64.deb.sha512" || echo "    ⚠️  .deb SHA512 not found"

# Arch package
echo "  → Arch package (.zst)"  
curl -fsSL -o "lyvoxa-$VERSION-linux-x86_64.tar.zst" "$BASE_URL/lyvoxa-$VERSION-linux-x86_64.tar.zst" || echo "    ⚠️  .zst not found"
curl -fsSL -o "lyvoxa-$VERSION-linux-x86_64.tar.zst.sha512" "$BASE_URL/lyvoxa-$VERSION-linux-x86_64.tar.zst.sha512" || echo "    ⚠️  .zst SHA512 not found"

# Unified files
echo "  → Unified verification files"
curl -fsSL -o "lyvoxa-$VERSION.checksums" "$BASE_URL/lyvoxa-$VERSION.checksums" || echo "    ⚠️  Unified checksums not found"
curl -fsSL -o "lyvoxa-$VERSION.sig.info" "$BASE_URL/lyvoxa-$VERSION.sig.info" || echo "    ⚠️  Signature info not found"

echo "✅ Download complete"
echo

# Verify checksums
echo "🔍 Verifying SHA512 checksums..."

# SHA512 verification for all packages
for file in lyvoxa-$VERSION-linux-x86_64.tar.gz lyvoxa_$VERSION-1_amd64.deb lyvoxa-$VERSION-linux-x86_64.tar.zst; do
  if [ -f "$file.sha512" ]; then
    echo "  → Verifying SHA512: $file"
    if sha512sum -c "$file.sha512"; then
      echo "    ✅ SHA512 verified"
    else
      echo "    ❌ SHA512 failed"
    fi
  else
    echo "    ⚠️  SHA512 checksum not found for: $file"
  fi
done

# Verify unified checksums if available
if [ -f "lyvoxa-$VERSION.checksums" ]; then
  echo "  → Verifying unified checksums file"
  if sha512sum -c "lyvoxa-$VERSION.checksums"; then
    echo "    ✅ All unified checksums verified"
  else
    echo "    ❌ Some unified checksums failed"
  fi
fi

echo
echo "📋 File Summary:"
ls -la

# Cleanup
echo
echo "🧹 Cleaning up..."
cd /
rm -rf "$TMP_DIR"
echo "✅ Verification complete!"
