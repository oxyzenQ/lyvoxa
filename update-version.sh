#!/bin/bash
# =============================================================================
# LYVOXA UNIVERSAL VERSION UPDATER
# =============================================================================
# Automatically updates version across all project files
# Usage: ./update-version.sh [new_version] [release_name] [release_number]
# Example: ./update-version.sh "1.6.0" "Matrix" "1.6"

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
VERSION_FILE="version.toml"
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Functions
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

log_header() {
    echo -e "${CYAN}$1${NC}"
}

# Parse version.toml file
parse_version_config() {
    if [[ ! -f "$VERSION_FILE" ]]; then
        log_error "Version configuration file not found: $VERSION_FILE"
        exit 1
    fi
    
    # Extract current values using grep and sed
    CURRENT_SEMANTIC=$(grep '^semantic = ' "$VERSION_FILE" | sed 's/semantic = "\(.*\)"/\1/')
    CURRENT_RELEASE_NAME=$(grep '^release_name = ' "$VERSION_FILE" | sed 's/release_name = "\(.*\)"/\1/')
    CURRENT_RELEASE_NUMBER=$(grep '^release_number = ' "$VERSION_FILE" | sed 's/release_number = "\(.*\)"/\1/')
    CURRENT_RELEASE_TAG=$(grep '^release_tag = ' "$VERSION_FILE" | sed 's/release_tag = "\(.*\)"/\1/')
}

# Update version.toml file
update_version_config() {
    local new_semantic="$1"
    local new_release_name="$2"
    local new_release_number="$3"
    local new_release_tag="${new_release_name,,}-${new_release_number}"
    
    log_info "Updating version configuration..."
    
    # Create backup
    cp "$VERSION_FILE" "$VERSION_FILE.backup"
    
    # Update version.toml
    sed -i "s/semantic = \".*\"/semantic = \"$new_semantic\"/" "$VERSION_FILE"
    sed -i "s/release_name = \".*\"/release_name = \"$new_release_name\"/" "$VERSION_FILE"
    sed -i "s/release_number = \".*\"/release_number = \"$new_release_number\"/" "$VERSION_FILE"
    sed -i "s/release_tag = \".*\"/release_tag = \"$new_release_tag\"/" "$VERSION_FILE"
    
    log_success "Version configuration updated"
}

# Update individual files
update_cargo_toml() {
    local new_version="$1"
    log_info "Updating Cargo.toml..."
    sed -i "s/^version = \".*\"/version = \"$new_version\"/" Cargo.toml
    log_success "✅ Cargo.toml updated"
}

update_readme() {
    local new_release_name="$1"
    local new_release_number="$2"
    local new_semantic="$3"
    log_info "Updating README.md..."
    
    # Update version line
    sed -i "s/\\*\\*Current Version\\*\\*: .*/\\*\\*Current Version\\*\\*: $new_release_name $new_release_number (v$new_semantic)/" README.md
    
    # Update download URLs
    local new_tag="${new_release_name,,}-${new_release_number}"
    sed -i "s|stellar-1\\.5|$new_tag|g" README.md
    
    log_success "✅ README.md updated"
}

update_changelog() {
    local new_semantic="$1"
    local new_release_name="$2"
    local new_release_number="$3"
    log_info "Updating CHANGELOG.md..."
    
    # Get current date
    local current_date=$(date +%Y-%m-%d)
    
    # Add new version entry at the top
    local new_entry="## [$new_semantic] - $new_release_name Edition - $current_date\\n\\n### 🌟 Major Features\\n- New features will be documented here\\n\\n"
    
    # Insert after the [Unreleased] section
    sed -i "/## \\[Unreleased\\]/a\\\\n$new_entry" CHANGELOG.md
    
    # Update version references
    sed -i "s/v1\\.5\\.0/v$new_semantic/g" CHANGELOG.md
    
    log_success "✅ CHANGELOG.md updated"
}

update_security_docs() {
    local new_tag="$1"
    log_info "Updating SECURITY.md..."
    
    # Update all stellar-1.5 references
    sed -i "s/stellar-1\\.5/$new_tag/g" SECURITY.md
    
    log_success "✅ SECURITY.md updated"
}

update_dockerfile() {
    local new_tag="$1"
    log_info "Updating Dockerfile..."
    
    # Update version comment and labels
    sed -i "s/# Version: .*/# Version: $new_tag/" Dockerfile
    sed -i "s/version=\".*\"/version=\"$new_tag\"/" Dockerfile
    sed -i "s/stellar-1\\.5/$new_tag/g" Dockerfile
    
    log_success "✅ Dockerfile updated"
}

update_docker_compose() {
    local new_tag="$1"
    log_info "Updating docker-compose.yml..."
    
    # Update version comment and image tag
    sed -i "s/# Version: .*/# Version: $new_tag/" docker-compose.yml
    sed -i "s/lyvoxa:stellar-1\\.5/lyvoxa:$new_tag/" docker-compose.yml
    
    log_success "✅ docker-compose.yml updated"
}

update_makefile() {
    local new_release_name="$1"
    local new_release_number="$2"
    log_info "Updating Makefile..."
    
    sed -i "s/# Version: .*/# Version: $new_release_name $new_release_number/" Makefile
    
    log_success "✅ Makefile updated"
}

update_build_script() {
    local new_release_name="$1"
    local new_release_number="$2"
    log_info "Updating build.sh..."
    
    # Update version comment and help text
    sed -i "s/# Version: .*/# Version: $new_release_name $new_release_number/" build.sh
    sed -i "s/Lyvoxa Build Script - .*/Lyvoxa Build Script - $new_release_name $new_release_number\"/" build.sh
    
    log_success "✅ build.sh updated"
}

update_workflows() {
    local new_tag="$1"
    local new_release_name="$2"
    local new_release_number="$3"
    local new_semantic="$4"
    
    log_info "Updating GitHub workflows..."
    
    # Update CI workflow
    sed -i "s/# Version: .*/# Version: $new_release_name $new_release_number/" .github/workflows/ci.yml
    sed -i "s/stellar-1\\.5/$new_tag/g" .github/workflows/ci.yml
    
    # Update release workflow
    sed -i "s/# Version: .*/# Version: $new_release_name $new_release_number/" .github/workflows/release.yml
    sed -i "s/default: 'stellar-1\\.5'/default: '$new_tag'/" .github/workflows/release.yml
    
    log_success "✅ GitHub workflows updated"
}

update_ssh_docs() {
    local new_tag="$1"
    log_info "Updating SSH signing documentation..."
    
    sed -i "s/stellar-1\\.5/$new_tag/g" docs/SETUP_SSH_SIGNING.md
    
    log_success "✅ SSH documentation updated"
}

# Main function
main() {
    log_header "🚀 LYVOXA UNIVERSAL VERSION UPDATER"
    echo ""
    
    # Parse current configuration
    parse_version_config
    
    log_info "Current version: $CURRENT_SEMANTIC ($CURRENT_RELEASE_NAME $CURRENT_RELEASE_NUMBER)"
    echo ""
    
    # Get new version from arguments or prompt
    if [[ $# -eq 0 ]]; then
        echo -e "${YELLOW}Enter new version information:${NC}"
        read -p "Semantic version (e.g., 1.6.0): " NEW_SEMANTIC
        read -p "Release name (e.g., Matrix): " NEW_RELEASE_NAME
        read -p "Release number (e.g., 1.6): " NEW_RELEASE_NUMBER
    elif [[ $# -eq 3 ]]; then
        NEW_SEMANTIC="$1"
        NEW_RELEASE_NAME="$2"
        NEW_RELEASE_NUMBER="$3"
    else
        log_error "Usage: $0 [semantic_version] [release_name] [release_number]"
        log_error "Example: $0 \"1.6.0\" \"Matrix\" \"1.6\""
        exit 1
    fi
    
    NEW_RELEASE_TAG="${NEW_RELEASE_NAME,,}-${NEW_RELEASE_NUMBER}"
    
    echo ""
    log_info "New version: $NEW_SEMANTIC ($NEW_RELEASE_NAME $NEW_RELEASE_NUMBER)"
    log_info "Release tag: $NEW_RELEASE_TAG"
    echo ""
    
    # Confirmation
    read -p "$(echo -e "${YELLOW}Proceed with version update? (y/N): ${NC}")" -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_warning "Version update cancelled"
        exit 0
    fi
    
    echo ""
    log_header "📝 UPDATING PROJECT FILES"
    echo ""
    
    # Update all files
    update_version_config "$NEW_SEMANTIC" "$NEW_RELEASE_NAME" "$NEW_RELEASE_NUMBER"
    update_cargo_toml "$NEW_SEMANTIC"
    update_readme "$NEW_RELEASE_NAME" "$NEW_RELEASE_NUMBER" "$NEW_SEMANTIC"
    update_changelog "$NEW_SEMANTIC" "$NEW_RELEASE_NAME" "$NEW_RELEASE_NUMBER"
    update_security_docs "$NEW_RELEASE_TAG"
    update_dockerfile "$NEW_RELEASE_TAG"
    update_docker_compose "$NEW_RELEASE_TAG"
    update_makefile "$NEW_RELEASE_NAME" "$NEW_RELEASE_NUMBER"
    update_build_script "$NEW_RELEASE_NAME" "$NEW_RELEASE_NUMBER"
    update_workflows "$NEW_RELEASE_TAG" "$NEW_RELEASE_NAME" "$NEW_RELEASE_NUMBER" "$NEW_SEMANTIC"
    update_ssh_docs "$NEW_RELEASE_TAG"
    
    echo ""
    log_header "🎉 VERSION UPDATE COMPLETE!"
    echo ""
    log_success "All files updated from $CURRENT_SEMANTIC to $NEW_SEMANTIC"
    log_success "Release: $CURRENT_RELEASE_NAME $CURRENT_RELEASE_NUMBER → $NEW_RELEASE_NAME $NEW_RELEASE_NUMBER"
    echo ""
    log_info "Next steps:"
    echo "  1. Review changes: git diff"
    echo "  2. Test build: ./build.sh release"
    echo "  3. Commit changes: git add . && git commit -m 'bump: version $NEW_SEMANTIC ($NEW_RELEASE_NAME $NEW_RELEASE_NUMBER)'"
    echo "  4. Create tag: git tag -a $NEW_RELEASE_TAG -m '$NEW_RELEASE_NAME $NEW_RELEASE_NUMBER Release'"
    echo "  5. Push: git push origin main && git push origin $NEW_RELEASE_TAG"
    echo ""
    log_warning "Backup created: $VERSION_FILE.backup"
}

# Run main function
main "$@"
