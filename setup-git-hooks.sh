#!/bin/bash
# =============================================================================
# GIT HOOKS SETUP SCRIPT
# =============================================================================
# Sets up Git hooks to run quality checks automatically
# Author: rezky_nightky
# Version: Stellar 3.0

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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

# Check if we're in a git repository
if [ ! -d ".git" ]; then
    log_error "Not in a git repository!"
    exit 1
fi

# shellcheck disable=SC2034
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GIT_HOOKS_DIR=".git/hooks"

log_info "Setting up Git hooks for Lyvoxa..."

# Create pre-commit hook
cat > "$GIT_HOOKS_DIR/pre-commit" << 'EOF'
#!/bin/bash
# Lyvoxa pre-commit hook
# Runs quality checks before allowing commit

echo "🔍 Running pre-commit quality checks..."
echo ""

# Run the pre-commit script with quick mode for commits
if ! ./pre-commit.sh --quick; then
    echo ""
    echo "❌ Pre-commit checks failed!"
    echo "Fix the issues above and try committing again."
    echo ""
    echo "💡 Tips:"
    echo "  • Run './pre-commit.sh' for full checks"
    echo "  • Run 'cargo fmt' to fix formatting"
    echo "  • Run 'cargo clippy --fix' to auto-fix linting"
    exit 1
fi

echo ""
echo "✅ Pre-commit checks passed!"
EOF

# Create pre-push hook
cat > "$GIT_HOOKS_DIR/pre-push" << 'EOF'
#!/bin/bash
# Lyvoxa pre-push hook
# Runs comprehensive quality checks before pushing

echo "🚀 Running pre-push quality checks..."
echo ""

# Run the full pre-commit script for pushes
if ! ./pre-commit.sh; then
    echo ""
    echo "❌ Pre-push checks failed!"
    echo "Fix the issues above before pushing."
    echo ""
    echo "💡 You can skip this check with:"
    echo "  git push --no-verify"
    echo ""
    echo "⚠️  But it's not recommended for production!"
    exit 1
fi

echo ""
echo "🎉 Pre-push checks passed! Ready to push to GitHub!"
EOF

# Make hooks executable
chmod +x "$GIT_HOOKS_DIR/pre-commit"
chmod +x "$GIT_HOOKS_DIR/pre-push"

log_success "Git hooks installed successfully!"
echo ""
log_info "Hooks installed:"
echo "  • pre-commit: Quick quality checks (formatting, clippy, build)"
echo "  • pre-push: Full quality checks (including tests and security audit)"
echo ""
log_info "To test the hooks:"
echo "  git add . && git commit -m 'test commit'  # Triggers pre-commit"
echo "  git push                                   # Triggers pre-push"
echo ""
log_info "To bypass hooks (not recommended):"
echo "  git commit --no-verify"
echo "  git push --no-verify"
