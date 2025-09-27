#!/bin/bash
# =============================================================================
# SSH KEY DEBUG HELPER
# =============================================================================
# Debug script to help identify SSH key format issues
# Usage: ./scripts/debug-ssh-key.sh

set -euo pipefail

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

echo "🔍 SSH Key Debug Helper"
echo "======================"
echo ""

# Check if SSH key exists
SSH_KEY_PATH="$HOME/.ssh/id_ed25519"
if [[ ! -f "$SSH_KEY_PATH" ]]; then
    log_error "No SSH key found at $SSH_KEY_PATH"
    log_info "Run ./scripts/setup-ssh-signing.sh to generate one"
    exit 1
fi

log_info "SSH key found: $SSH_KEY_PATH"
echo ""

# Show key information
log_info "SSH Key Analysis:"
echo "================="
echo "File permissions: $(stat -c %A "$SSH_KEY_PATH")"
echo "File size: $(wc -c < "$SSH_KEY_PATH") bytes"
echo "File type: $(file "$SSH_KEY_PATH")"
echo ""

# Show key fingerprint
log_info "Key Fingerprint:"
echo "==============="
ssh-keygen -l -f "$SSH_KEY_PATH"
echo ""

# Show key format
log_info "Key Format Check:"
echo "================="
FIRST_LINE=$(head -1 "$SSH_KEY_PATH")
LAST_LINE=$(tail -1 "$SSH_KEY_PATH")

echo "First line: $FIRST_LINE"
echo "Last line: $LAST_LINE"
echo ""

if [[ "$FIRST_LINE" == "-----BEGIN OPENSSH PRIVATE KEY-----" ]]; then
    log_success "✅ Key starts with correct OpenSSH header"
else
    log_error "❌ Key does not start with OpenSSH header"
    log_warning "Expected: -----BEGIN OPENSSH PRIVATE KEY-----"
    log_warning "Found: $FIRST_LINE"
fi

if [[ "$LAST_LINE" == "-----END OPENSSH PRIVATE KEY-----" ]]; then
    log_success "✅ Key ends with correct OpenSSH footer"
else
    log_error "❌ Key does not end with OpenSSH footer"
    log_warning "Expected: -----END OPENSSH PRIVATE KEY-----"
    log_warning "Found: $LAST_LINE"
fi

echo ""

# Test signing capability
log_info "Signing Test:"
echo "============="
TEST_FILE="/tmp/ssh_sign_test.txt"
echo "test content for signing" > "$TEST_FILE"

if ssh-keygen -Y sign -f "$SSH_KEY_PATH" -n file "$TEST_FILE" >/dev/null 2>&1; then
    log_success "✅ SSH signing test PASSED"
    log_info "Your SSH key can be used for signing"
    rm -f "$TEST_FILE" "$TEST_FILE.sig"
else
    log_error "❌ SSH signing test FAILED"
    log_warning "This key cannot be used for signing"
    log_info "Try generating a new ED25519 key"
fi

echo ""

# Show formats for GitHub Secrets
log_info "GitHub Secrets Formats:"
echo "======================="

echo ""
echo "📋 Format 1: Raw key (copy exactly as shown):"
echo "--------------------------------------------"
cat "$SSH_KEY_PATH"
echo ""

echo "📋 Format 2: Base64 encoded:"
echo "----------------------------"
base64 -w 0 "$SSH_KEY_PATH"
echo ""
echo ""

echo "📋 Format 3: Single line (spaces instead of newlines):"
echo "-----------------------------------------------------"
tr '\n' ' ' < "$SSH_KEY_PATH"
echo ""
echo ""

# Instructions
log_info "Troubleshooting Steps:"
echo "====================="
echo "1. If signing test failed:"
echo "   - Generate new key: ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519 -N ''"
echo "   - Ensure key is ED25519 type"
echo ""
echo "2. For GitHub Secrets (SSH_SIGN_KEY):"
echo "   - Use Format 1 (raw key) - most reliable"
echo "   - Copy including -----BEGIN and -----END lines"
echo "   - Ensure no extra spaces or characters"
echo ""
echo "3. If GitHub Actions still fails:"
echo "   - Try Format 2 (base64 encoded)"
echo "   - Check workflow logs for detailed error messages"
echo "   - Verify public key is added to GitHub account"
echo ""

log_success "Debug analysis complete!"
