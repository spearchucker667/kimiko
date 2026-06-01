# Git Bash Installation Guide

Git Bash (included with Git for Windows) provides a POSIX-like shell environment on Windows. Kimiko's `.sh` scripts work in Git Bash with a few caveats.

## Prerequisites

- [Git for Windows](https://git-scm.com/download/win) installed
- `make` available (install via `choco install make` or use the one bundled with Git for Windows)
- Python 3.11+ (if running validator tests)

## Installation

```bash
# 1. Clone the repo
git clone https://github.com/spearchucker667/kimiko.git
cd kimiko

# 2. Run the installer
make install

# 3. Source the mandate activation
source ~/.kimi/activate-mandate.sh

# 4. Launch Kimi with the mandate wrapper
~/.kimi/launch-with-mandate.sh
```

## Important Caveats

### File Permissions

Git Bash runs on Windows with an NTFS filesystem. The `chmod` command is **emulated** and does not actually change NTFS ACLs. The Makefile will run `chmod` without error, but the permissions are not enforced by the filesystem.

**Recommendation**: If you store sensitive files in `~/.kimi/`, ensure your Windows user account is the only one with access. You can verify this in File Explorer → Properties → Security tab.

### Path Quirks

Git Bash translates Windows paths:
- `C:\Users\YourName` becomes `/c/Users/YourName`
- `$HOME` resolves to `/c/Users/YourName` (your Windows user profile)

This is usually transparent, but be aware if you manually edit paths.

### Line Endings

If you clone with `core.autocrlf=true`, shell scripts may get Windows line endings (`CRLF`). This can break Bash scripts. To fix:

```bash
dos2unix ~/.kimi/*.sh
```

Or configure Git to preserve line endings for this repo:

```bash
git config core.autocrlf false
```

### Symbolic Links

Git Bash supports symbolic links, but they require Administrator privileges or Developer Mode enabled in Windows Settings.

## Verification

After installation, run:

```bash
make verify
```

All checks should pass. The permission checks will report success (since `chmod` doesn't fail) but the actual NTFS ACLs are not verified.
