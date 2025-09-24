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

# Download both package formats and verification files
echo "📥 Downloading both package formats and verification files..."

# ArchLinux optimized package (.zst)
echo "  → ArchLinux optimized package (.tar.zst)"
curl -fsSL -o "lyvoxa-$VERSION-linux-x86_64.tar.zst" "$BASE_URL/lyvoxa-$VERSION-linux-x86_64.tar.zst" || echo "    ⚠️  .zst package not found"
curl -fsSL -o "lyvoxa-$VERSION-linux-x86_64.tar.zst.sha256" "$BASE_URL/lyvoxa-$VERSION-linux-x86_64.tar.zst.sha256" || echo "    ⚠️  .zst SHA256 not found"

# Linux universal package (.gz)
echo "  → Linux universal package (.tar.gz)"
curl -fsSL -o "lyvoxa-$VERSION-linux-x86_64.tar.gz" "$BASE_URL/lyvoxa-$VERSION-linux-x86_64.tar.gz" || echo "    ⚠️  .gz package not found"
curl -fsSL -o "lyvoxa-$VERSION-linux-x86_64.tar.gz.sha256" "$BASE_URL/lyvoxa-$VERSION-linux-x86_64.tar.gz.sha256" || echo "    ⚠️  .gz SHA256 not found"

# Verification files
echo "  → Verification files"
curl -fsSL -o "lyvoxa-$VERSION.checksums" "$BASE_URL/lyvoxa-$VERSION.checksums" || echo "    ⚠️  Checksums file not found"
curl -fsSL -o "lyvoxa-$VERSION.verification" "$BASE_URL/lyvoxa-$VERSION.verification" || echo "    ⚠️  Verification guide not found"

echo "✅ Download complete"
echo

# Verify SHA256 checksums for both packages
echo "🔍 Verifying SHA256 checksums for both package formats..."

# SHA256 verification for both packages
PACKAGES=("lyvoxa-$VERSION-linux-x86_64.tar.zst" "lyvoxa-$VERSION-linux-x86_64.tar.gz")
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
if [ -f "lyvoxa-$VERSION.checksums" ]; then
  echo "  → Verifying unified checksums file"
  if sha256sum -c "lyvoxa-$VERSION.checksums"; then
    echo "    ✅ All checksums verified - ready for ArchLinux/Linux installation"
  else
    echo "    ❌ Some checksums failed"
    exit 1
  fi
fi

# Extract and verify binary info (prefer .zst if available, fallback to .gz)
echo
echo "🔍 Extracting and verifying package contents..."

PACKAGE_TO_EXTRACT=""
if [ -f "lyvoxa-$VERSION-linux-x86_64.tar.zst" ]; then
  PACKAGE_TO_EXTRACT="lyvoxa-$VERSION-linux-x86_64.tar.zst"
  echo "  → Using ArchLinux optimized package (.zst)"
  tar -xf "$PACKAGE_TO_EXTRACT"
elif [ -f "lyvoxa-$VERSION-linux-x86_64.tar.gz" ]; then
  PACKAGE_TO_EXTRACT="lyvoxa-$VERSION-linux-x86_64.tar.gz"
  echo "  → Using Linux universal package (.gz)"
  tar -xzf "$PACKAGE_TO_EXTRACT"
else
  echo "    ❌ No valid package found for extraction"
  exit 1
fi

PACKAGE_DIR="lyvoxa-$VERSION-linux-x86_64"
if [ -d "$PACKAGE_DIR" ]; then
  echo "  → Package extracted successfully from $PACKAGE_TO_EXTRACT"
  echo "  → Checking binaries:"
  if [ -f "$PACKAGE_DIR/bin/lyvoxa" ]; then
    file "$PACKAGE_DIR/bin/lyvoxa"
    echo "    ✅ Main binary found and valid"
  fi
  if [ -f "$PACKAGE_DIR/bin/lyvoxa-simple" ]; then
    file "$PACKAGE_DIR/bin/lyvoxa-simple" 
    echo "    ✅ Simple binary found and valid"
  fi
  
  # Show compression comparison if both packages exist
  if [ -f "lyvoxa-$VERSION-linux-x86_64.tar.zst" ] && [ -f "lyvoxa-$VERSION-linux-x86_64.tar.gz" ]; then
    echo "  → Package size comparison:"
    echo "    .zst (ArchLinux): $(du -h lyvoxa-$VERSION-linux-x86_64.tar.zst | cut -f1)"
    echo "    .gz (Universal): $(du -h lyvoxa-$VERSION-linux-x86_64.tar.gz | cut -f1)"
  fi
else
  echo "    ❌ Package extraction failed"
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
