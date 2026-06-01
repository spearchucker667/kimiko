# Troubleshooting Guide

Platform-specific issues and their resolutions.

---

## macOS

### `make: command not found`

macOS ships with BSD make at `/usr/bin/make`. If it's missing, install Xcode Command Line Tools:

```bash
xcode-select --install
```

### `chmod: unable to change file mode`

This should not happen on macOS. If it does, the file may be on a non-native filesystem (network drive, exFAT). Move the repository to your local APFS drive.

### `kimi: command not found`

The Kimi Code CLI binary is not in your PATH or not installed. Install it first:

```bash
# Via uv (recommended)
uv tool install kimi-cli

# Or follow the official instructions at https://www.moonshot.cn/
```

---

## Git Bash

### `make: command not found`

Git Bash does not include `make` by default. Install it via:

```bash
# Via Chocolatey
choco install make

# Via MSYS2 (if installed)
pacman -S make
```

Or use the Git Bash installer options to include MinGW build tools.

### `chmod` appears to work but permissions don't change

This is expected. Git Bash emulates `chmod` on NTFS, but the actual ACLs are not modified. The file appears to have the right permissions in `ls -l` but any Windows user can still read it.

**Fix**: Use Windows Explorer → Properties → Security tab to set actual ACLs, or run `make permissions` for PowerShell `icacls` commands.

### `bad interpreter: No such file or directory`

Line endings were converted to CRLF during clone.

**Fix**:

```bash
dos2unix ~/.kimi/*.sh
```

> **Note:** `dos2unix` is not installed by default on Git Bash. Install it via `pacman -S dos2unix` (MSYS2) or download the standalone binary.

Or re-clone with:

```bash
git config core.autocrlf false
git clone https://github.com/spearchucker667/kimiko.git
```

### Scripts fail with `command not found` for basic utilities

Git Bash may not have all utilities in PATH. Ensure your Git for Windows installation includes the full POSIX toolset (default in recent versions).

---

## WSL

### `make install` puts files in the wrong place

If `$HOME` resolves to `/mnt/c/Users/...` instead of `/home/...`, your WSL distribution may be misconfigured.

**Fix**: Ensure you are running the command inside WSL, not from a Windows terminal:

```bash
# In WSL
echo $HOME
# Should print: /home/<your-username>
```

### Files installed to `/mnt/c/` have wrong permissions

WSL mounted drives (`/mnt/c/`, `/mnt/d/`) use NTFS with different permission semantics. `chmod` may not work as expected.

**Fix**: Install Kimiko in WSL's native filesystem:

```bash
cd ~  # Ensure you are in /home/<user>
git clone https://github.com/spearchucker667/kimiko.git
cd kimiko
make install
```

### Kimi binary not found in WSL

If you installed Kimi CLI on Windows (not inside WSL), the binary is not in WSL's PATH.

**Fix**:

```bash
# Option 1: Add Windows path to WSL PATH
export PATH="$PATH:/mnt/c/Users/$USER/.local/bin"

# Option 2: Install Kimi CLI inside WSL directly
```

### WSL clock is out of sync

If `git clone` or other network operations fail with certificate errors, WSL's clock may have drifted.

**Fix**:

```bash
sudo hwclock -s
```

---

## PowerShell

### `cannot be loaded because running scripts is disabled`

PowerShell's execution policy prevents running `.ps1` scripts.

**Fix**:

```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### `kimi-wrapper.ps1` cannot find the Kimi binary

The script searches for `kimi.exe` in several locations but may not find yours.

**Fix**: Check where your Kimi CLI is installed:

```powershell
Get-Command kimi -ErrorAction SilentlyContinue
# or
Get-ChildItem -Path "$env:LOCALAPPDATA\Programs" -Recurse -Filter "kimi.exe"
```

Then either add that directory to your PATH or create a symlink in one of the searched locations.

### JSON parse error in `kimi.json`

The template substitution may produce invalid JSON if `$env:USERPROFILE` contains backslashes.

**Fix**: The install script should convert backslashes to forward slashes. If you installed manually, verify:

```powershell
$json = Get-Content "$env:USERPROFILE\.kimi\kimi.json" -Raw
$null = $json | ConvertFrom-Json
```

If this fails, re-render the template with proper escaping.

### `make` is not recognized in PowerShell

PowerShell does not include `make`. You have two options:

1. **Use `make install-windows`** (if make is installed):
   ```powershell
   make install-windows
   ```

2. **Install make via Chocolatey**:
   ```powershell
   choco install make
   ```

3. **Manual copy** (see [`INSTALL-WINDOWS.md`](./INSTALL-WINDOWS.md)).

---

## Validator

### `jsonschema` or `pyyaml` not found

Install the validator dependencies:

```bash
# macOS / Linux / WSL / Git Bash
cd validator
pip install -r requirements.txt

# PowerShell
cd validator
python -m pip install -r requirements.txt
```

### `check_file_permissions` fails on Git Bash

This is expected. The validator uses Unix `stat.S_IMODE()` which does not reflect actual NTFS ACLs. On Git Bash and Windows, permission checks are skipped.

### Tests fail on Windows with permission errors

The pytest suite includes tests that call `os.chmod()`. These are skipped on Windows automatically.

If you see other failures, ensure you are using Python 3.11+ and have installed all dependencies.

---

## General

### `config.toml does not contain 'kimiko'`

The installed `config.toml` may be stale or from a different source.

**Fix**:

```bash
# Reinstall
make uninstall
make install
make verify
```

### Mirror sync fails (`make sync`)

`config.toml` and `kimi.toml` (or the two mandate YAMLs) have drifted.

**Fix**: Manually sync the files or copy one to the other:

```bash
cp config/config.toml config/kimi.toml
# Then re-add the kimi.toml comment header
cp config/mandate-agent.yaml config/mandate-kimiko-agent.yaml
```

### Kimi CLI does not load the mandate

Ensure you are launching through the wrapper or have sourced the activation script:

```bash
# macOS / WSL / Git Bash
source ~/.kimi/activate-mandate.sh
~/.kimi/launch-with-mandate.sh

# PowerShell
. $env:USERPROFILE\.kimi\activate-mandate.ps1
& $env:USERPROFILE\.kimi\launch-with-mandate.ps1
```

Launching `kimi` directly (without wrapper) will not load the mandate configuration.
