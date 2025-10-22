# Dependabot Auto-Merge Setup Guide

This guide explains how to configure Dependabot for automatic dependency updates with near-direct commits to the main branch.

## 📋 Overview

The Dependabot configuration includes:

- **Cargo (Rust) dependencies**: Weekly updates for all dependencies
- **GitHub Actions**: Weekly updates for workflow actions
- **Auto-merge workflow**: Automatically merges PRs after CI passes
- **Grouped updates**: Patches and minor updates are grouped together
- **Smart labeling**: Auto-labels PRs for easy filtering and automation

## 🚀 Quick Setup

### 1. Enable Dependabot in Repository Settings

Go to your repository settings and enable Dependabot:

```
Settings → Code security and analysis → Dependabot
```

Enable:
- ✅ **Dependabot alerts**
- ✅ **Dependabot security updates**
- ✅ **Dependabot version updates**

### 2. Enable Auto-Merge

Enable auto-merge in your repository settings:

```
Settings → General → Pull Requests
```

Enable:
- ✅ **Allow auto-merge**
- ✅ **Allow squash merging** (recommended)

### 3. Configure Branch Protection (Optional but Recommended)

Set up branch protection for the main branch:

```
Settings → Branches → Add branch protection rule
```

Configure:
- **Branch name pattern**: `main`
- ✅ **Require a pull request before merging**
- ✅ **Require status checks to pass before merging**
  - Select: `Code Quality`, `Build and Test (Linux x86_64)`
- ✅ **Require conversation resolution before merging**
- ✅ **Allow auto-merge**

### 4. Grant Dependabot Permissions

Ensure the Dependabot has proper permissions:

```
Settings → Actions → General → Workflow permissions
```

Set to:
- ✅ **Read and write permissions**
- ✅ **Allow GitHub Actions to create and approve pull requests**

## 📝 Configuration Files

### `.github/dependabot.yml`

Main configuration file that defines:
- Update schedules (weekly on Monday at 3 AM UTC)
- Package ecosystems to monitor (cargo, github-actions)
- Grouping strategies for updates
- Commit message conventions
- Labels and reviewers

### `.github/workflows/dependabot-auto-merge.yml`

Automation workflow that:
- Auto-approves patch and minor updates
- Waits for CI checks to complete
- Auto-merges PRs that pass all checks
- Labels major updates for manual review
- Notifies on failures

## 🔧 How It Works

### Update Flow

1. **Monday 3 AM UTC**: Dependabot checks for updates
2. **PR Creation**: Creates PRs for outdated dependencies
3. **Auto-Approval**: Workflow automatically approves patch/minor updates
4. **CI Checks**: Waits for all CI checks to pass
5. **Auto-Merge**: Merges PR to main branch automatically
6. **Cleanup**: Deletes the PR branch

### Update Types

| Update Type | Behavior | Example |
|------------|----------|---------|
| **Patch** | Auto-merge immediately | `1.0.0` → `1.0.1` |
| **Minor** | Auto-merge after review | `1.0.0` → `1.1.0` |
| **Major** | Manual review required | `1.0.0` → `2.0.0` |

### Grouping Strategy

Updates are grouped to reduce PR noise:

- **patch-updates**: All patch updates in one PR
- **minor-updates**: All minor updates in one PR
- **dev-dependencies**: Development dependencies grouped separately

## 🏷️ Labels

Dependabot PRs are automatically labeled:

- `dependencies`: All dependency updates
- `rust`: Rust/Cargo dependency updates
- `github-actions`: GitHub Actions updates
- `auto-merge`: PRs eligible for auto-merge
- `manual-review-required`: Major updates needing review

## 🛡️ Safety Features

### Automatic Safety Checks

- ✅ Waits for CI to pass before merging
- ✅ Squash merges to keep history clean
- ✅ Labels major updates for manual review
- ✅ Notifies on merge failures
- ✅ Limits open PRs to prevent spam

### Manual Override

You can still manually review and merge any PR:

```bash
# Review the PR
gh pr view <PR_NUMBER>

# Manually merge
gh pr merge <PR_NUMBER> --squash

# Or close if not needed
gh pr close <PR_NUMBER>
```

## 🎯 Customization

### Adjust Update Schedule

Edit `.github/dependabot.yml`:

```yaml
schedule:
  interval: "daily"  # Options: daily, weekly, monthly
  day: "monday"      # For weekly updates
  time: "03:00"      # UTC time
```

### Change Auto-Merge Behavior

Edit `.github/workflows/dependabot-auto-merge.yml`:

```yaml
# Only auto-merge patch updates
if: steps.metadata.outputs.update-type == 'version-update:semver-patch'

# Or auto-merge all updates (not recommended)
if: steps.metadata.outputs.update-type != ''
```

### Ignore Specific Dependencies

Edit `.github/dependabot.yml`:

```yaml
ignore:
  - dependency-name: "sysinfo"
    update-types: ["version-update:semver-major"]
  - dependency-name: "ratatui"
    # Ignore all updates for this package
```

### Change Reviewers

Edit `.github/dependabot.yml`:

```yaml
reviewers:
  - "your-username"
  - "team-name"
assignees:
  - "your-username"
```

## 🔍 Monitoring

### View Dependabot Activity

Check Dependabot logs:

```
Insights → Dependency graph → Dependabot
```

### Check PR Status

View all Dependabot PRs:

```bash
gh pr list --author "dependabot[bot]"
```

### View Dependency Graph

```
Insights → Dependency graph → Dependencies
```

## 🐛 Troubleshooting

### PRs Not Auto-Merging

Check:
1. ✅ Auto-merge is enabled in settings
2. ✅ Workflow permissions are set correctly
3. ✅ CI checks are passing
4. ✅ Branch protection rules allow auto-merge

### Dependabot Not Creating PRs

Check:
1. ✅ Dependabot is enabled in settings
2. ✅ `dependabot.yml` syntax is correct
3. ✅ Schedule has been reached
4. ✅ Dependencies are outdated (check manually)

### CI Failing on Dependabot PRs

Check:
1. ✅ Dependencies are compatible with each other
2. ✅ Tests are up to date
3. ✅ CI workflow has correct triggers
4. ✅ No breaking changes in updates

## 📚 Best Practices

### Long-Term Maintenance

1. **Review major updates**: Always manually review major version updates
2. **Test before merge**: Ensure CI is comprehensive
3. **Monitor changelogs**: Check release notes for breaking changes
4. **Keep CI fast**: Fast CI enables quick auto-merges
5. **Regular audits**: Review dependency graph monthly

### Security

1. **Enable security updates**: Always keep security updates enabled
2. **Review vulnerability alerts**: Check Dependabot alerts regularly
3. **Pin critical versions**: Pin versions for critical dependencies
4. **Use lockfiles**: Keep `Cargo.lock` in version control

### Performance

1. **Limit open PRs**: Prevent PR spam with `open-pull-requests-limit`
2. **Group updates**: Reduce noise with update groups
3. **Schedule wisely**: Run during low-activity hours
4. **Optimize CI**: Fast CI = fast auto-merges

## 🔗 Additional Resources

- [Dependabot Documentation](https://docs.github.com/en/code-security/dependabot)
- [GitHub Actions Auto-Merge](https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/incorporating-changes-from-a-pull-request/automatically-merging-a-pull-request)
- [Cargo Dependencies](https://doc.rust-lang.org/cargo/reference/specifying-dependencies.html)

## 💡 Tips

- Use `--dry-run` flags when testing automation
- Monitor the first few weeks to tune the configuration
- Adjust grouping strategies based on your needs
- Consider different schedules for different ecosystems
- Keep the auto-merge workflow simple and maintainable

---

**Status**: ✅ Configured and ready to use  
**Last Updated**: 2025-10-22  
**Maintainer**: @oxyzenQ
