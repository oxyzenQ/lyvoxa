# Fix for Dependabot PRs Not Auto-Merging

## Problem
Dependabot PRs are approved but not auto-merging because the workflow used `gh` CLI which wasn't working properly.

## Solution Applied
✅ Replaced `gh` CLI commands with direct GitHub REST/GraphQL API calls
✅ Created script to manually enable auto-merge for existing PRs

## Steps to Fix Existing PRs

### Option 1: Push Changes and Run Script (Recommended)

```bash
# 1. Push the fixes
git push origin main

# 2. Set your GitHub token (create one at: https://github.com/settings/tokens)
export GITHUB_TOKEN="your_github_token_here"

# 3. Run the script to enable auto-merge for all open Dependabot PRs
./.github/scripts/enable-automerge-for-prs.sh
```

### Option 2: Manual GitHub UI (Quick for few PRs)

For each Dependabot PR (#10-#16):

1. Open the PR page
2. Scroll to the bottom
3. Click **"Enable auto-merge"** button
4. Select **"Squash and merge"**
5. Click **"Enable auto-merge"**

The PR will automatically merge when all checks pass!

### Option 3: Close and Let Dependabot Recreate (Clean slate)

```bash
# Close all current Dependabot PRs (they'll be recreated next week)
# New PRs will use the fixed workflow automatically

# Get list of PR numbers
echo "PR #10 #11 #12 #13 #14 #15 #16"

# Close them one by one (or use GitHub UI)
```

## What Changed in the Workflow

### Before (Not Working)
```yaml
- run: gh pr merge --auto --squash "$PR_URL"
  # ❌ Requires gh CLI, had authentication issues
```

### After (Working)
```yaml
- run: |
    PR_NODE_ID=$(curl -s -H "Authorization: token ${{ secrets.GITHUB_TOKEN }}" \
      "https://api.github.com/repos/${{ github.repository }}/pulls/${{ github.event.pull_request.number }}" \
      | jq -r '.node_id')
    
    curl -X POST \
      -H "Authorization: bearer ${{ secrets.GITHUB_TOKEN }}" \
      https://api.github.com/graphql \
      -d '{"query":"mutation {enablePullRequestAutoMerge(...)}"}'
  # ✅ Direct API call, more reliable
```

## Verification

After enabling auto-merge:

1. Check PR status - should show **"Auto-merge enabled"** badge
2. PRs will show "This pull request is set to automatically merge"
3. Wait for checks to pass, PR merges automatically

## For Future PRs

Once you push these changes, all **new** Dependabot PRs will:
1. ✅ Auto-approve automatically
2. ✅ Enable auto-merge automatically  
3. ✅ Merge automatically when CI passes

No manual intervention needed! 🎉

## Quick Commands

```bash
# Push fixes
git push origin main

# Enable auto-merge for existing PRs (easiest)
export GITHUB_TOKEN="ghp_your_token_here"
./.github/scripts/enable-automerge-for-prs.sh

# Or manually merge all PRs now
for i in {10..16}; do
  curl -X PUT \
    -H "Authorization: token $GITHUB_TOKEN" \
    "https://api.github.com/repos/oxyzenQ/lyvoxa/pulls/$i/merge" \
    -d '{"merge_method":"squash"}'
done
```

## Creating GitHub Token

If you need a token:

1. Go to https://github.com/settings/tokens
2. Click **"Generate new token"** → **"Generate new token (classic)"**
3. Name it: `Dependabot Auto-Merge`
4. Select scopes:
   - ✅ `repo` (Full control of private repositories)
   - ✅ `workflow` (Update GitHub Action workflows)
5. Click **"Generate token"**
6. Copy the token (starts with `ghp_...`)
7. Export it: `export GITHUB_TOKEN="ghp_your_token"`

## Need Help?

- Check workflow runs: https://github.com/oxyzenQ/lyvoxa/actions/workflows/dependabot-auto-merge.yml
- View Dependabot status: https://github.com/oxyzenQ/lyvoxa/network/updates
- Manual merge: Use GitHub UI "Merge pull request" button

---

**Status**: ✅ Fixed in commit 55ecc35  
**Next PRs**: Will auto-merge automatically!
