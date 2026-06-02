# WSL Installation Guide

Windows Subsystem for Linux (WSL) provides a full Linux environment on Windows. Kimiko works natively in WSL with **no caveats** — all features work exactly as they do on macOS and native Linux.

## Prerequisites

- WSL2 installed with a Linux distribution (Ubuntu recommended)
- `make`, `python3`, and standard POSIX tools (usually pre-installed)

## Installation

```bash
# 1. Clone the repo inside WSL (recommended)
git clone https://github.com/spearchucker667/kimiko.git
cd kimiko

# 2. Run the installer
make install

# 3. Source the mandate activation
source ~/.kimi/activate-mandate.sh

# 4. Launch Kimi with the mandate wrapper
~/.kimi/launch-with-mandate.sh
```

## Where to Install

**Recommendation**: Install Kimiko inside WSL's own filesystem (`~/.kimi` in WSL), not in a Windows-mounted directory (`/mnt/c/...`).

WSL's native filesystem (`ext4`) supports proper Unix permissions (`chmod 600` works correctly). Windows-mounted drives (`/mnt/c/`, `/mnt/d/`) use NTFS with different permission semantics.

### Good

```bash
make install  # Installs to /home/<user>/.kimi — native WSL filesystem
```

### Avoid

```bash
# Don't install to a Windows-mounted drive
make install DEST=/mnt/c/Users/YourName/.kimi
```

## Accessing Windows Files

If you need to access Kimiko files from Windows Explorer, you can navigate to:

```
\\wsl$\<distro-name>\home\<username>\.kimi
```

For example, for Ubuntu:

```
\\wsl$\Ubuntu\home\spearchucker\.kimi
```

## Kimi Binary Location

If you installed Kimi Code CLI on Windows (not inside WSL), you can still invoke it from WSL by using its Windows path:

```bash
# Add Windows kimi to WSL PATH
export PATH="$PATH:/mnt/c/Users/$USER/.local/bin"

# Or create a wrapper
ln -s "/mnt/c/Users/$USER/.local/bin/kimi.exe" ~/.local/bin/kimi
```

Alternatively, install Kimi CLI inside WSL directly for the cleanest experience.

## Verification

After installation, run:

```bash
make verify
```

All checks should pass, including permission checks, since WSL uses a real Linux filesystem.
