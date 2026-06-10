<img width="2290" height="687" alt="ChatGPT Image Jun 1, 2026 at 06_18_14 AM" src="https://github.com/user-attachments/assets/2373228d-2d54-4677-bd94-acba16b52402" />

# Kimiko Security Policy

## Offensive Security Focus

**Kimiko** is an offensive security configuration framework. By its very nature, it generates and processes highly sensitive, adversarial data. Securing your local Kimiko installation is paramount to preventing accidental leaks of exploits, payloads, or reconnaissance data.

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
- **Encrypt your workspace.** Since Kimiko is used for pentesting, ensure your `~/.kimi-code` and associated work directories are on an encrypted partition (e.g., FileVault on macOS, LUKS on Linux, BitLocker on Windows).
- **Run `make verify` after installation** to confirm files landed with correct permissions.
- **Review scripts** before sourcing them into your shell environment.

### macOS / Linux / WSL

- **Use `chmod 600`** on `config.toml`, `kimi.toml`, and mandate YAML files after any manual edits.
- Verify with `ls -la ~/.kimi-code`.
- **WSL note:** WSL uses the native Linux filesystem, so Unix permissions are fully enforced.

### Windows (PowerShell)

- NTFS uses ACLs instead of Unix permission bits.
- To restrict access to `%USERPROFILE%\.kimi-code`:
  ```powershell
  icacls $env:USERPROFILE\.kimi-code /inheritance:r
  icacls $env:USERPROFILE\.kimi-code /grant:r $env:USERNAME:(OI)(CI)F
  ```
- Ensure PowerShell execution policy is set appropriately: `Set-ExecutionPolicy RemoteSigned -Scope CurrentUser`.

### Data Handling

- **Sanitize outputs.** Before sharing any Kimi Pentest output, verify it doesn't contain local paths, usernames, or sensitive network identifiers.
- **Isolate your pentesting environment.** If possible, run Kimiko within a dedicated VM or container to prevent side-channel leaks to your host system.
