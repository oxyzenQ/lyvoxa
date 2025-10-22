#!/bin/bash
# =============================================================================
# Enable Auto-Merge for Open Dependabot PRs
# =============================================================================
# This script enables auto-merge for all open Dependabot PRs
# Usage: ./enable-automerge-for-prs.sh
# =============================================================================

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}╔════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║        Enable Auto-Merge for Dependabot PRs                    ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Check if GITHUB_TOKEN is set
if [ -z "$GITHUB_TOKEN" ]; then
    echo -e "${YELLOW}⚠  GITHUB_TOKEN not set. Trying to use gh CLI...${NC}"
    
    # Try to get token from gh CLI
    if command -v gh >/dev/null 2>&1; then
        GITHUB_TOKEN=$(gh auth token 2>/dev/null || echo "")
    fi
    
    if [ -z "$GITHUB_TOKEN" ]; then
        echo "Error: GITHUB_TOKEN environment variable is not set"
        echo "Please set it with: export GITHUB_TOKEN=your_token"
        echo "Or authenticate with: gh auth login"
        exit 1
    fi
fi

# Get repository info
REPO=$(git config --get remote.origin.url | sed 's/.*github.com[:/]\(.*\)\.git/\1/' | sed 's/.*github.com[:/]\(.*\)/\1/')
echo -e "${BLUE}Repository:${NC} $REPO"
echo ""

# Get all open Dependabot PRs
echo "Fetching open Dependabot PRs..."
PRS=$(curl -s -H "Authorization: token $GITHUB_TOKEN" \
    -H "Accept: application/vnd.github.v3+json" \
    "https://api.github.com/repos/$REPO/pulls?state=open&per_page=100" \
    | jq -r '.[] | select(.user.login == "dependabot[bot]") | "\(.number)|\(.title)|\(.node_id)"')

if [ -z "$PRS" ]; then
    echo -e "${YELLOW}No open Dependabot PRs found.${NC}"
    exit 0
fi

# Process each PR
echo "$PRS" | while IFS='|' read -r PR_NUMBER TITLE NODE_ID; do
    echo -e "${BLUE}▶ PR #$PR_NUMBER:${NC} $TITLE"
    
    # Enable auto-merge using GraphQL API
    RESPONSE=$(curl -s -X POST \
        -H "Authorization: bearer $GITHUB_TOKEN" \
        -H "Content-Type: application/json" \
        https://api.github.com/graphql \
        -d "{\"query\":\"mutation {enablePullRequestAutoMerge(input:{pullRequestId:\\\"$NODE_ID\\\",mergeMethod:SQUASH}){pullRequest{autoMergeRequest{enabledAt}}}}\"}")
    
    # Check if successful
    if echo "$RESPONSE" | jq -e '.data.enablePullRequestAutoMerge.pullRequest.autoMergeRequest.enabledAt' >/dev/null 2>&1; then
        ENABLED_AT=$(echo "$RESPONSE" | jq -r '.data.enablePullRequestAutoMerge.pullRequest.autoMergeRequest.enabledAt')
        echo -e "  ${GREEN}✓ Auto-merge enabled${NC} (enabled at: $ENABLED_AT)"
    else
        ERROR=$(echo "$RESPONSE" | jq -r '.errors[0].message // "Unknown error"')
        echo -e "  ${YELLOW}⚠ Failed to enable auto-merge: $ERROR${NC}"
    fi
    echo ""
done

echo -e "${GREEN}✓ Done!${NC}"
echo ""
echo "PRs will now automatically merge when all required checks pass."
echo "Check status at: https://github.com/$REPO/pulls"
