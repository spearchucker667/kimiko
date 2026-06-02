# Windows Installation Guide

Kimiko supports three Windows environments: **Git Bash**, **WSL**, and **PowerShell**. Choose the one that matches your workflow.

---

## Quick Comparison

| Environment | Best For | Permissions | Shell Scripts |
|---|---|---|---|
| **Git Bash** | Users who already use Git for Windows | Emulated (`chmod` no-op) | `.sh` (mostly work) |
| **WSL** | Developers who want native Linux behavior | Real (`chmod` works) | `.sh` (fully compatible) |
| **PowerShell** | Native Windows users, sysadmins | ACL-based | `.ps1` (native) |

---

## Option 1: Git Bash

### Prerequisites

- [Git for Windows](https://git-scm.com/download/win)
- `make` (install via `choco install make` or MSYS2)
- Python 3.11+ (optional, for validator tests)

### Installation

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

### Important Notes

- **File permissions**: `chmod` is emulated on NTFS and does not enforce actual ACLs. See `make permissions` for Windows ACL guidance.
- **Line endings**: If you cloned with `core.autocrlf=true`, run `dos2unix ~/.kimi/*.sh` to fix line endings.
- **Paths**: `$HOME` resolves to `/c/Users/YourName` in Git Bash.

See [`scripts/INSTALL-GITBASH.md`](../scripts/INSTALL-GITBASH.md) for detailed Git Bash-specific guidance.

---

## Option 2: WSL (Recommended)

### Prerequisites

- WSL2 with a Linux distribution (Ubuntu recommended)
- Standard POSIX tools (`make`, `python3` — usually pre-installed)

### Installation

```bash
# 1. Clone the repo inside WSL (not in /mnt/c/)
git clone https://github.com/spearchucker667/kimiko.git
cd kimiko

# 2. Run the installer
make install

# 3. Source the mandate activation
source ~/.kimi/activate-mandate.sh

# 4. Launch Kimi with the mandate wrapper
~/.kimi/launch-with-mandate.sh
```

### Why WSL is Recommended

- **Real Unix permissions**: `chmod 600` works correctly on WSL's `ext4` filesystem.
- **Full compatibility**: All `.sh` scripts, Makefile targets, and validator tests work without modification.
- **No path translation issues**: Install in WSL home (`~/.kimi`), not a Windows-mounted drive.

### Accessing WSL Files from Windows

```
\\wsl$\Ubuntu\home\<username>\.kimi
```

See [`scripts/INSTALL-WSL.md`](../scripts/INSTALL-WSL.md) for detailed WSL guidance.

---

## Option 3: PowerShell

### Prerequisites

- PowerShell 7+ (`pwsh`) — [download here](https://github.com/PowerShell/PowerShell/releases)
- Python 3.11+ (optional, for validator tests)
- Kimi Code CLI installed and available in PATH or at `~/.local/bin/kimi.exe`

### Installation

> **Note on Home Directory:** The installer detects your home directory using the following priority: `USERPROFILE` → `HOME` → `TEMP`. In most PowerShell environments, `USERPROFILE` is used. If all variables are missing (e.g. in some CI environments), the installer will fallback to `TEMP`.

If you have `make` installed (via Chocolatey or MSYS2), use the one-liner:

```powershell
make install-windows
```

If you do **not** have `make`, perform the manual steps below:

```powershell
# 1. Clone the repo
git clone https://github.com/spearchucker667/kimiko.git
cd kimiko

# 2. Create the .kimi directory
New-Item -ItemType Directory -Force -Path "$env:USERPROFILE\.kimi"

# 3. Copy config files
Copy-Item -Path "config\*" -Destination "$env:USERPROFILE\.kimi" -Recurse -Force

# 4. Copy PowerShell scripts
Copy-Item -Path "scripts\*.ps1" -Destination "$env:USERPROFILE\.kimi" -Force

# 5. Copy validator
Copy-Item -Path "validator" -Destination "$env:USERPROFILE\.kimi" -Recurse -Force

# 6. Render kimi.json from template
$template = Get-Content "config\kimi.json.template" -Raw
$template = $template.Replace("<YOUR_HOME_DIR>", $env:USERPROFILE.Replace("\", "/"))
$template | Set-Content "$env:USERPROFILE\.kimi\kimi.json" -NoNewline
```

### Activation

```powershell
# Load the mandate in the current session
. $env:USERPROFILE\.kimi\activate-mandate.ps1

# Or add to your PowerShell profile for permanent activation
Add-Content $PROFILE ". `$env:USERPROFILE\.kimi\kimi-shell-integration.ps1"
```

### Launch

```powershell
# Quick launcher with status banner
& $env:USERPROFILE\.kimi\launch-with-mandate.ps1

# Or directly via wrapper
& $env:USERPROFILE\.kimi\kimi-wrapper.ps1
```

### Important Notes

- **Execution policy**: You may need to run `Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser` to allow PowerShell scripts to run.
- **File permissions**: Windows NTFS uses ACLs, not Unix permissions. Run `make permissions` for ACL guidance.
- **Binary location**: The PowerShell scripts search for `kimi.exe` in multiple locations. If yours is elsewhere, add its directory to your PATH.

---

## Post-Installation Verification

Regardless of platform, verify the installation:

### Git Bash / WSL

```bash
make verify
```

### PowerShell

```powershell
# Verify files exist
$files = @("config.toml", "kimi.toml", "mandate-agent.yaml", "mandate-kimiko-agent.yaml", "activate-mandate.ps1")
foreach ($f in $files) {
    $path = Join-Path $env:USERPROFILE ".kimi" $f
    if (Test-Path $path) { Write-Host "OK: $f" } else { Write-Host "MISSING: $f" }
}

# Verify JSON valid
$json = Get-Content "$env:USERPROFILE\.kimi\kimi.json" -Raw
$null = $json | ConvertFrom-Json
Write-Host "kimi.json: valid JSON"

# Verify kimiko references
$config = Get-Content "$env:USERPROFILE\.kimi\config.toml" -Raw
if ($config -match "kimiko") { Write-Host "config.toml: references kimiko" }
```

---

## Next Steps

- Read [`AGENTS.md`](./AGENTS.md) for a deep-dive into the mandate architecture.
- Read [`TROUBLESHOOTING.md`](./TROUBLESHOOTING.md) for platform-specific issue resolution.
- Review [`SECURITY.md`](./SECURITY.md) for Windows security best practices.
