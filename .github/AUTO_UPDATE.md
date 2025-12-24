# Auto Update Dependencies

This repository uses a scheduled GitHub Actions workflow to update `Cargo.lock`.

## Workflow

File:

- `.github/workflows/auto-update.yml`

What it does:

- Runs `cargo update`
- Runs `cargo audit` (non-blocking)
- Builds and runs tests
- Optionally runs a clippy sanity check
- Pushes directly to `main` or opens a PR (workflow input)

## Manual trigger

Run it from GitHub:

- Actions
- Auto Update Dependencies
- Run workflow
