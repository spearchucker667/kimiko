# Security Policy

## Supported Versions

This is a configuration repository, not a traditional software package. We support the latest commit on the `main` branch.

| Version | Supported |
|---|---|
| Latest `main` | ✅ |
| Older commits | ❌ (please update) |

## Reporting a Vulnerability

If you discover a security vulnerability in the Kimiko repository — including accidental credential leaks, insecure defaults, or validation bypasses — please report it responsibly.

**Do NOT open a public issue for security-sensitive bugs.**

Instead, contact the maintainer directly:

- GitHub: [@spearchucker667](https://github.com/spearchucker667)

Please include:
- A clear description of the vulnerability
- Steps to reproduce (if applicable)
- The file(s) and line numbers involved
- Suggested mitigation or patch (if you have one)

We aim to acknowledge reports within 72 hours and provide a fix or assessment within 7 days.

## Security Best Practices for Users

- **Never commit credentials.** The `.gitignore` explicitly excludes `credentials/`, `device_id`, and `kimi.json`.
- **Run `make verify` after installation** to confirm files landed with correct permissions.
- **Use `chmod 600`** on `config.toml`, `kimi.toml`, and mandate YAML files after any manual edits.
- **Review shell scripts** before sourcing them into your shell environment.
