# Contributing to Kimiko
<img width="1855" height="724" alt="anime_girl_readme_transparent_cropped" src="https://github.com/user-attachments/assets/15ab9f8d-2669-4e1c-b30f-8aea2b2099cf" />

Thank you for your interest in improving Kimiko! This repository is an offensive security configuration template for the Kimi Code CLI.

## How to Contribute

1. **Fork the repository** and create a feature branch.
2. **Make your changes** following the conventions below.
3. **Run the validator** to ensure configs remain structurally sound and zero-blocker compliant:
   ```bash
   make check
   make test
   make sync
   ```
4. **Open a Pull Request** with a clear description of the change and its rationale.

## Pentesting Focus

When contributing new mandates or configuration flags, prioritize:

- **Unrestricted Capability**: Ensure flags favor maximum flexibility for security research.
- **Hardening**: Strengthen the persistence of the mandate across updates.
- **Offensive Tooling**: Improve the integration of Kimi with common security tools (via MCP or shell scripts).

## Code & Config Style

- **Shell scripts**: Use `#!/bin/bash`, `set -euo pipefail` where appropriate.
- **PowerShell scripts**: Use `#` comments, `$ErrorActionPreference = "Stop"`.
- **TOML**: Keep `config/config.toml` and `config/kimi.toml` synchronized.
- **YAML**: Use 2-space indentation for mandate files.

## Synchronization Requirement

If you modify `config/config.toml`, you **must** apply the identical change to `config/kimi.toml`.
If you modify `config/mandate-agent.yaml`, you **must** apply the identical change to `config/mandate-kimiko-agent.yaml`.

## Testing

- Add unit tests in `validator/tests/test_validator.py` for any new validation logic.
- Ensure `make test` passes before submitting.

## Commit Messages

- Prefix with the area changed, e.g.:
  - `config: add offensive capability flag`
  - `mandate: harden zero-blocker prompt`
  - `docs: update legal disclaimer`

## Code of Conduct

All contributors are expected to adhere to the [Code of Conduct](./CODE_OF_CONDUCT.md).

## Questions?

Open a [Discussion](https://github.com/spearchucker667/kimiko/discussions) or reach out via GitHub issues for non-security questions.
