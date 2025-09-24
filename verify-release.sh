#!/bin/bash
# Lyvoxa Professional Package Verification Script
# Usage: ./verify-release.sh stellar-2.0

set -e

VERSION=${1:-stellar-2.0}
BASE_URL="https://github.com/oxyzenQ/lyvoxa/releases/download/$VERSION"

echo "🔐 Lyvoxa Release Verification - $VERSION"
echo "=========================================="

# Create temp directory
TMP_DIR=$(mktemp -d)
cd "$TMP_DIR"
echo "📁 Working in: $TMP_DIR"
echo

# Download release package and checksum (.tar.gz only)
echo "📥 Downloading release package and checksum..."

echo "  → Linux universal package (.tar.gz)"
curl -fsSL -o "lyvoxa-$VERSION-linux-x86_64.tar.gz" "$BASE_URL/lyvoxa-$VERSION-linux-x86_64.tar.gz" || echo "    ⚠️  .gz package not found"
curl -fsSL -o "lyvoxa-$VERSION-linux-x86_64.tar.gz.sha256" "$BASE_URL/lyvoxa-$VERSION-linux-x86_64.tar.gz.sha256" || echo "    ⚠️  .gz SHA256 not found"

echo "✅ Download complete"
echo

# Verify SHA256 checksum
echo "🔍 Verifying SHA256 checksum..."

# SHA256 verification for the package
PACKAGES=("lyvoxa-$VERSION-linux-x86_64.tar.gz")
VERIFIED_COUNT=0

for PACKAGE in "${PACKAGES[@]}"; do
  if [ -f "$PACKAGE" ] && [ -f "$PACKAGE.sha256" ]; then
    echo "  → Verifying SHA256: $PACKAGE"
    if sha256sum -c "$PACKAGE.sha256"; then
      echo "    ✅ SHA256 verified - $(basename $PACKAGE) integrity confirmed"
      VERIFIED_COUNT=$((VERIFIED_COUNT + 1))
      
      # Show package size
      echo "    📋 Size: $(du -h "$PACKAGE" | cut -f1)"
    else
      echo "    ❌ SHA256 failed - $PACKAGE may be corrupted"
    fi
  else
    echo "    ⚠️  Package or checksum not found for: $PACKAGE"
  fi
done

if [ $VERIFIED_COUNT -eq 0 ]; then
  echo "    ❌ No packages could be verified"
  exit 1
else
  echo "    ✅ $VERIFIED_COUNT package(s) verified successfully"
fi

# Verify unified checksums if available
# Unified checksums file is no longer produced

# Extract and verify binary info (.gz only)
echo
echo "🔍 Extracting and verifying package contents..."

PACKAGE_TO_EXTRACT="lyvoxa-$VERSION-linux-x86_64.tar.gz"
if [ -f "$PACKAGE_TO_EXTRACT" ]; then
  echo "  → Using Linux universal package (.gz)"
  tar -xzf "$PACKAGE_TO_EXTRACT"
else
  echo "    ❌ No valid package found for extraction"
  exit 1
fi

# Our tarball contains binaries at the root after extraction
if [ -f "lyvoxa" ]; then
  echo "  → Checking binaries:"
  file "lyvoxa" || true
  [ -f "lyvoxa-simple" ] && file "lyvoxa-simple" || true
  echo "    ✅ Binaries found and inspected"
else
  echo "    ❌ Expected binaries not found after extraction"
  exit 1
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
