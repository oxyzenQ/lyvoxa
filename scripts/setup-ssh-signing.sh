#!/bin/bash
# =============================================================================
# SSH SIGNING SETUP HELPER
# =============================================================================
# Helper script to setup SSH signing for GitHub releases
# Usage: ./scripts/setup-ssh-signing.sh

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

echo "🔑 SSH Signing Setup Helper"
echo "=========================="
echo ""

# Check if SSH key exists
SSH_KEY_PATH="$HOME/.ssh/id_ed25519"
if [[ ! -f "$SSH_KEY_PATH" ]]; then
    log_info "No SSH key found. Generating new ED25519 key..."
    ssh-keygen -t ed25519 -C "lyvoxa-release-signing" -f "$SSH_KEY_PATH" -N ""
    log_success "SSH key generated: $SSH_KEY_PATH"
else
    log_info "Existing SSH key found: $SSH_KEY_PATH"
fi

echo ""
log_info "SSH Key Information:"
ssh-keygen -l -f "$SSH_KEY_PATH"
echo ""

# Show public key
log_info "Public key (add to GitHub account):"
echo "=================================="
cat "$SSH_KEY_PATH.pub"
echo ""

# Show private key for GitHub Secrets
log_info "Private key for GitHub Secrets:"
echo "==============================="
log_warning "Copy this ENTIRE output (including headers) to GitHub Secrets as SSH_SIGN_KEY:"
echo ""
echo "🔑 Raw private key (RECOMMENDED - copy exactly as shown):"
echo "--------------------------------------------------------"
cat "$SSH_KEY_PATH"
echo ""

echo "🔑 Base64 encoded (alternative if raw doesn't work):"
echo "---------------------------------------------------"
base64 -w 0 "$SSH_KEY_PATH"
echo ""
echo ""

# Test signing locally
log_info "Testing SSH signing locally:"
echo "============================"
echo "test signing" > /tmp/test_sign.txt
if ssh-keygen -Y sign -f "$SSH_KEY_PATH" -n file /tmp/test_sign.txt >/dev/null 2>&1; then
    log_success "✅ SSH signing test passed - key is valid for signing"
    rm -f /tmp/test_sign.txt /tmp/test_sign.txt.sig
else
    log_error "❌ SSH signing test failed - key may not be suitable for signing"
    log_warning "Try generating a new ED25519 key or check key permissions"
fi
echo ""

# Instructions
log_info "Setup Instructions:"
echo "=================="
echo "1. Copy the PUBLIC key above and add it to your GitHub account:"
echo "   https://github.com/settings/keys"
echo ""
echo "2. Copy the PRIVATE key above and add it to GitHub repository secrets:"
echo "   https://github.com/oxyzenQ/lyvoxa/settings/secrets/actions"
echo "   Secret name: SSH_SIGN_KEY"
echo ""
echo "3. Test the setup by creating a release:"
echo "   git tag -a test-1.0 -m 'Test release'"
echo "   git push origin test-1.0"
echo ""

# Verification
log_info "Verification Commands:"
echo "====================="
echo "# Test signing locally:"
echo "echo 'test' > test.txt"
echo "ssh-keygen -Y sign -f $SSH_KEY_PATH -n file test.txt"
echo ""
echo "# Test verification:"
echo "curl -s https://github.com/oxyzenQ.keys > oxyzenQ.pub"
echo "ssh-keygen -Y verify -f oxyzenQ.pub -I file -n file -s test.txt.sig < test.txt"
echo ""

log_success "SSH signing setup complete!"
log_info "Remember to keep your private key secure and never share it publicly."
