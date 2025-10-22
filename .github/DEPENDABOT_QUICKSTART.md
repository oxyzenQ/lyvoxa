# Dependabot Quick Start Guide

## 🚀 Get Started in 5 Minutes

### Step 1: Commit the Configuration

```bash
# Add all Dependabot files
git add .github/dependabot.yml
git add .github/workflows/dependabot-auto-merge.yml
git add .github/DEPENDABOT_SETUP.md
git add .github/DEPENDABOT_QUICKSTART.md
git add .github/scripts/check-dependabot-config.sh

# Commit the configuration
git commit -m "chore: add Dependabot configuration with auto-merge

- Add Dependabot config for Cargo and GitHub Actions
- Configure auto-merge workflow for dependency updates
- Add setup documentation and verification script
- Enable automatic dependency maintenance"

# Push to GitHub
git push origin main
```

### Step 2: Enable in GitHub Settings

#### A. Enable Dependabot (2 minutes)

1. Go to your repository on GitHub
2. Click **Settings** → **Code security and analysis**
3. Enable these features:
   - ✅ **Dependabot alerts**
   - ✅ **Dependabot security updates**
   - ✅ **Dependabot version updates**

#### B. Enable Auto-Merge (1 minute)

1. Go to **Settings** → **General**
2. Scroll to **Pull Requests** section
3. Enable:
   - ✅ **Allow auto-merge**
   - ✅ **Allow squash merging**

#### C. Configure Workflow Permissions (2 minutes)

1. Go to **Settings** → **Actions** → **General**
2. Scroll to **Workflow permissions**
3. Select:
   - ✅ **Read and write permissions**
4. Enable:
   - ✅ **Allow GitHub Actions to create and approve pull requests**

### Step 3: Verify Configuration

Run the verification script:

```bash
./.github/scripts/check-dependabot-config.sh
```

This will check if everything is configured correctly.

### Step 4: Test (Optional)

You can trigger Dependabot manually to test:

1. Go to **Insights** → **Dependency graph** → **Dependabot**
2. Click **Check for updates** on each ecosystem
3. Dependabot will create PRs if updates are available

## 📋 What Happens Next?

### Automatic Schedule

- **Every Monday at 3:00 AM UTC**: Dependabot checks for updates
- **Within minutes**: Creates PRs for outdated dependencies
- **After CI passes**: Auto-merges patch and minor updates
- **Major updates**: Labeled for manual review

### First Run

The first time Dependabot runs, it may create multiple PRs:

1. Review the PRs to ensure everything looks correct
2. Check that CI passes on all PRs
3. Verify auto-merge works as expected
4. Manually merge major updates after reviewing changelogs

## 🎯 Common Scenarios

### Scenario 1: Patch Update (Automatic)

```
1. Dependabot: Creates PR for sysinfo 0.29.0 → 0.29.1
2. GitHub Actions: Auto-approves PR
3. CI: Runs tests (5-10 minutes)
4. GitHub Actions: Auto-merges PR
5. Result: Dependency updated without any manual action ✅
```

### Scenario 2: Minor Update (Automatic with Review)

```
1. Dependabot: Creates PR for ratatui 0.30.0 → 0.31.0
2. GitHub Actions: Auto-approves PR
3. CI: Runs tests (5-10 minutes)
4. GitHub Actions: Auto-merges PR
5. Result: Dependency updated automatically ✅
```

### Scenario 3: Major Update (Manual Review)

```
1. Dependabot: Creates PR for tokio 1.0 → 2.0
2. GitHub Actions: Labels as "manual-review-required"
3. You: Review changelog and breaking changes
4. You: Manually merge or update code as needed
5. Result: Safe upgrade with manual oversight ✅
```

## 🛠️ Customization

### Change Update Frequency

Edit `.github/dependabot.yml`:

```yaml
schedule:
  interval: "daily"  # or "weekly" or "monthly"
```

### Auto-Merge Only Patches

Edit `.github/workflows/dependabot-auto-merge.yml`:

Change line 92-94 to:

```yaml
if: |
  steps.wait-for-checks.outputs.conclusion == 'success' &&
  steps.metadata.outputs.update-type == 'version-update:semver-patch'
```

### Ignore Specific Dependencies

Edit `.github/dependabot.yml`, add to the cargo section:

```yaml
ignore:
  - dependency-name: "ratatui"
    update-types: ["version-update:semver-major"]
```

## 🔍 Monitoring

### View Dependabot Activity

```bash
# List all Dependabot PRs
gh pr list --author "dependabot[bot]"

# View specific PR
gh pr view <PR_NUMBER>

# Check Dependabot logs (on GitHub)
# Insights → Dependency graph → Dependabot
```

### Check Outdated Dependencies

```bash
# For Rust/Cargo
cargo outdated

# Install cargo-outdated if needed
cargo install cargo-outdated
```

## 🐛 Troubleshooting

### PRs Not Being Created

**Check:**
1. Wait until Monday 3 AM UTC (next scheduled run)
2. Verify Dependabot is enabled in settings
3. Run manual check: Insights → Dependency graph → Dependabot → Check for updates

### Auto-Merge Not Working

**Check:**
1. Is auto-merge enabled? (Settings → General → Pull Requests)
2. Are workflow permissions correct? (Settings → Actions → General)
3. Did CI pass? Check the PR status
4. Is it a major update? (requires manual review)

**Debug:**
```bash
# Check workflow runs
gh run list --workflow="Dependabot Auto-Merge"

# View specific run
gh run view <RUN_ID>
```

### CI Failing

**Check:**
1. Are the dependency updates compatible?
2. Do tests need updating?
3. Check the CI logs for details

**Fix:**
```bash
# Checkout the PR branch locally
gh pr checkout <PR_NUMBER>

# Run tests locally
cargo test

# Fix issues and push
git commit -am "fix: update tests for new dependencies"
git push
```

## 📚 Additional Resources

- **Full Setup Guide**: `.github/DEPENDABOT_SETUP.md`
- **Verification Script**: `.github/scripts/check-dependabot-config.sh`
- **Dependabot Docs**: https://docs.github.com/en/code-security/dependabot
- **GitHub Actions Docs**: https://docs.github.com/en/actions

## ✅ Checklist

Before considering setup complete:

- [ ] Configuration files committed and pushed
- [ ] Dependabot enabled in repository settings
- [ ] Auto-merge enabled in repository settings
- [ ] Workflow permissions configured
- [ ] Verification script passes all checks
- [ ] First Dependabot PR successfully created and merged
- [ ] Team notified about automatic updates

## 🎉 Success!

Once everything is set up, Dependabot will:

- 🔄 Keep dependencies up to date automatically
- 🔒 Alert you to security vulnerabilities
- 🚀 Merge safe updates without manual intervention
- 📊 Provide dependency insights
- 🛡️ Maintain code quality with CI checks

Your repository is now set up for long-term automated maintenance!

---

**Need Help?**
- Check the full setup guide: `.github/DEPENDABOT_SETUP.md`
- Review Dependabot logs: Insights → Dependency graph → Dependabot
- Run verification: `./.github/scripts/check-dependabot-config.sh`
