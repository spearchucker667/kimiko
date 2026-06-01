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

### All Platforms

- **Never commit credentials.** The `.gitignore` explicitly excludes `credentials/`, `device_id`, and `kimi.json`.
- **Run `make verify` after installation** to confirm files landed with correct permissions.
- **Review scripts** before sourcing them into your shell environment.

### macOS / Linux / WSL

- **Use `chmod 600`** on `config.toml`, `kimi.toml`, and mandate YAML files after any manual edits.
- Verify with `ls -la ~/.kimi`.
- **WSL note:** WSL uses the native Linux filesystem, so Unix permissions are fully enforced. Running `make permissions` on WSL will report "Unix permissions are enforced by the filesystem on this platform." — this is correct WSL behavior.

### Windows (Git Bash)

- Git Bash emulates `chmod` on NTFS, but the actual ACLs are not modified.
- Use Windows Explorer → Properties → Security tab to verify actual file permissions.
- To view `icacls` commands, open a native PowerShell session and run `make permissions` (Git Bash will show a different message).

### Windows (PowerShell)

- NTFS uses ACLs instead of Unix permission bits.
- To restrict access to `%USERPROFILE%\.kimi`:
  ```powershell
  icacls $env:USERPROFILE\.kimi /inheritance:r
  icacls $env:USERPROFILE\.kimi /grant:r $env:USERNAME:(OI)(CI)F
  ```
- Ensure PowerShell execution policy is set appropriately: `Set-ExecutionPolicy RemoteSigned -Scope CurrentUser`.
