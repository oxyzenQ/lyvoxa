# Contributing to Lyvoxa

Thank you for your interest in contributing! This guide outlines how to work on Lyvoxa in a secure, professional, and welcoming way.

## Ground Rules

- Keep changes focused and incremental.
- Follow Rust idioms and maintain readability/performance.
- Prefer minimal dependencies and stable APIs.
- For security-sensitive code, add rationale in comments.

## Developer Certificate of Origin (DCO)

Lyvoxa uses the Developer Certificate of Origin (DCO). By contributing, you certify that you wrote the code or otherwise have the right to submit it under the open-source license used by the project.

To agree to the DCO, every commit must contain a Signed-off-by line with your legal name and email address, like this:

```
Signed-off-by: Your Name <you@example.com>
```

The easiest way to do this is to use `-s` when committing:

```
git commit -s -m "Add new feature"
```

Pull requests that do not include Signed-off-by lines for each commit may be rejected by CI.

## How to Contribute

1. Fork the repository and create a feature branch.
2. Make your changes.
3. Ensure build passes:
   - `cargo build --release -j 3`
4. Run linters/tests (if applicable).
5. Commit with `-s` to include the DCO footer.
6. Open a pull request. Fill out the PR template.

## Coding Style

- Rust edition 2024.
- Keep functions small and focused; prefer explicit over clever.
- Add comments for non-trivial logic and security-sensitive paths.
- Keep UI strings and UX consistent with existing patterns.

## Security

- Do not include secrets in code or CI.
- Report vulnerabilities privately if needed; otherwise open an issue with reproduction steps.

## License

By contributing, you agree that your contributions are licensed under the GPL-3.0-or-later license.
