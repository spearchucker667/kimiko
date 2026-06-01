# Contributing to Kimiko

Thank you for your interest in improving Kimiko! This repository is a sanitized, public-ready configuration template for the Kimi Code CLI.

## How to Contribute

1. **Fork the repository** and create a feature branch.
2. **Make your changes** following the conventions below.
3. **Run the validator** to ensure configs remain structurally sound:
   ```bash
   cd validator
   make test
   make validate
   ```
4. **Open a Pull Request** with a clear description of the change and its rationale.

## Code & Config Style

- **Shell scripts**: Use `#!/bin/bash`, `set -euo pipefail` where appropriate, and `${HOME}` for portability.
- **TOML**: Prefer section headers over inline tables. Keep `config.toml` and `kimi.toml` synchronized.
- **YAML**: Use 2-space indentation for mandate files.
- **JSON**: Use 2-space indentation for schemas.
- **Python (validator)**: Follow PEP 8. Use type hints. Run `make lint` before committing.

## Synchronization Requirement

If you modify `config.toml`, you **must** apply the identical change to `kimi.toml`.  
If you modify `mandate-agent.yaml`, you **must** apply the identical change to `mandate-kimiko-agent.yaml`.

PRs that introduce drift between these file pairs will be rejected.

## Testing

- Add unit tests in `validator/tests/test_validator.py` for any new validation logic.
- Use `tmp_path` fixtures for filesystem-dependent tests.
- Ensure `make test` passes before submitting.

## Commit Messages

- Use concise, descriptive commit messages.
- Prefix with the area changed, e.g.:
  - `config: add new authorized setting`
  - `validator: fix false positive in secret scanner`
  - `docs: update AGENTS.md troubleshooting`

## Questions?

Open a [Discussion](https://github.com/spearchucker667/kimiko/discussions) or reach out via GitHub issues for non-security questions.
