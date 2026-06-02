# Contributing to Kimiko
<img width="1855" height="724" alt="anime_girl_readme_transparent_cropped" src="https://github.com/user-attachments/assets/15ab9f8d-2669-4e1c-b30f-8aea2b2099cf" />

Thank you for your interest in improving Kimiko! This repository is a sanitized, public-ready cross-platform configuration template for the Kimi Code CLI.

## How to Contribute

1. **Fork the repository** and create a feature branch.
2. **Make your changes** following the conventions below.
3. **Run the validator** to ensure configs remain structurally sound:
   ```bash
   # From the repo root (validates source configs, not installed files)
   make check
   make test
   make sync

   # Or run validator directly against repo sources
   cd validator
   python3 validate_kimi.py config ../config/config.toml
   python3 validate_kimi.py mandate ../config/mandate-agent.yaml
   python3 validate_kimi.py compliance ../config
   ```
   To validate your installed `~/.kimi` directory instead:
   ```bash
   make install   # first, to populate ~/.kimi
   cd ~/.kimi/validator
   make test
   make validate
   ```

   ### Platform Notes for Contributors

   | Target | macOS / Linux / WSL | Git Bash | PowerShell |
   |---|---|---|---|
   | `make check` | ✅ Full structural + compliance validation | ✅ Structural only (compliance requires Python) | ❌ Run python validator directly |
   | `make test` | ✅ Runs pytest suite | ✅ Runs pytest suite | ❌ Use WSL or Git Bash |
   | `make sync` | ✅ Byte-for-byte sync check | ❌ Fails (no `cmp`/`diff` in PATH) | ❌ Fails (no Unix tools) |
   | `make verify` | ✅ Post-install verification | ✅ Post-install verification | ✅ Post-install verification |
   | `make install` | ✅ `~/.kimi` | ✅ `~/.kimi` | ✅ `~/.kimi` |

   > **Why `make sync` fails on Windows:** `make sync` uses `cmp` and `diff` to enforce byte-for-byte identity between `config.toml`↔`kimi.toml` and the two mandate YAMLs. These tools are not available in native PowerShell. Use WSL or Git Bash with MSYS build tools for `make sync`.
4. **Open a Pull Request** with a clear description of the change and its rationale.

## Code & Config Style

- **Shell scripts**: Use `#!/bin/bash`, `set -euo pipefail` where appropriate, and `${HOME}` for portability.
- **PowerShell scripts**: Use `#` comments, `$ErrorActionPreference = "Stop"`, and `$env:USERPROFILE` for paths.
- **TOML**: Prefer section headers over inline tables. Keep `config/config.toml` and `config/kimi.toml` synchronized.
- **YAML**: Use 2-space indentation for mandate files.
- **JSON**: Use 2-space indentation for schemas.
- **Python (validator)**: Follow PEP 8. Use type hints. Run `make lint` before committing. Use `pathlib.Path` for all paths. Gate platform-specific code with `platform.system()`.

## Synchronization Requirement

If you modify `config/config.toml`, you **must** apply the identical change to `config/kimi.toml`.
If you modify `config/mandate-agent.yaml`, you **must** apply the identical change to `config/mandate-kimiko-agent.yaml`.

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

## Code of Conduct

All contributors are expected to adhere to the [Code of Conduct](./CODE_OF_CONDUCT.md).

## Questions?

Open a [Discussion](https://github.com/spearchucker667/kimiko/discussions) or reach out via GitHub issues for non-security questions.
