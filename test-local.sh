#!/bin/bash
# =============================================================================
# LOCAL BUILD TEST SCRIPT
# =============================================================================
# Test builds locally before pushing to GitHub
# Run this before committing to catch issues early
# Author: rezky_nightky
# =============================================================================

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}   Local Build Test for Lyvoxa${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Step 1: Format check
echo -e "${YELLOW}[1/5]${NC} Running cargo fmt check..."
if cargo fmt --check; then
    echo -e "${GREEN}✅ Format check passed${NC}"
else
    echo -e "${RED}❌ Format check failed - run 'cargo fmt'${NC}"
    exit 1
fi
echo ""

# Step 2: Clippy (without LTO flags)
echo -e "${YELLOW}[2/5]${NC} Running clippy..."
unset RUSTFLAGS
if cargo clippy --all-targets --all-features -- -D warnings; then
    echo -e "${GREEN}✅ Clippy passed${NC}"
else
    echo -e "${RED}❌ Clippy failed${NC}"
    exit 1
fi
echo ""

# Step 3: Tests
echo -e "${YELLOW}[3/5]${NC} Running tests..."
if cargo test --target x86_64-unknown-linux-gnu; then
    echo -e "${GREEN}✅ Tests passed${NC}"
else
    echo -e "${RED}❌ Tests failed${NC}"
    exit 1
fi
echo ""

# Step 4: Debug build
echo -e "${YELLOW}[4/5]${NC} Building debug version..."
if cargo build --target x86_64-unknown-linux-gnu; then
    echo -e "${GREEN}✅ Debug build succeeded${NC}"
    ls -lh target/x86_64-unknown-linux-gnu/debug/lyvoxa
else
    echo -e "${RED}❌ Debug build failed${NC}"
    exit 1
fi
echo ""

# Step 5: Optimized release build (with size optimization)
echo -e "${YELLOW}[5/5]${NC} Building optimized release..."
export RUSTFLAGS="-C opt-level=z -C lto=fat -C codegen-units=1 -C strip=symbols"
if cargo build --release --target x86_64-unknown-linux-gnu; then
    echo -e "${GREEN}✅ Release build succeeded${NC}"
    
    BINARY="target/x86_64-unknown-linux-gnu/release/lyvoxa"
    strip --strip-all "$BINARY" 2>/dev/null || true
    
    echo ""
    echo -e "${BLUE}📊 Binary Analysis:${NC}"
    echo -e "  Size: $(du -h $BINARY | cut -f1)"
    echo -e "  Type: $(file $BINARY)"
else
    echo -e "${RED}❌ Release build failed${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}   ✅ All tests passed!${NC}"
echo -e "${GREEN}   Ready to commit and push${NC}"
echo -e "${GREEN}========================================${NC}"
