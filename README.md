# Kimiko

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![CI](https://github.com/spearchucker667/kimiko/actions/workflows/ci.yml/badge.svg)](https://github.com/spearchucker667/kimiko/actions/workflows/ci.yml)
![macOS](https://img.shields.io/badge/macOS-supported-blue?logo=apple)
![Windows](https://img.shields.io/badge/Windows-Git%20Bash%20%7C%20WSL%20%7C%20PowerShell-blue?logo=windows)
![Linux](https://img.shields.io/badge/Linux-supported-blue?logo=linux)
![Python](https://img.shields.io/badge/Python-3.11+-blue?logo=python)

<img width="1774" height="887" alt="Kimiko project banner" src="https://github.com/user-attachments/assets/2cd40966-0aae-4262-83d7-ceb551a4b192" />

A cross-platform configuration repository that reproduces the zero-blocker mandate behavior for the [Kimi Code CLI](https://www.moonshot.cn/).

When you enter **`kimiko`** in a Kimi CLI session, the full authorization/config flow activates—exactly like the original private `~/.kimi` setup, but without any personal credentials, session data, or machine-specific secrets.

---

## What This Project Does

Kimiko packages the shared, reproducible parts of a `~/.kimi` directory into a single Makefile-driven installer. After installation:

- Your local `~/.kimi/` contains the hardened **config.toml**, **kimi.toml**, mandate agent specs, shell integration scripts, and the built-in **validator** tool.
- Launching `kimi` via the wrapper or shell integration loads the mandate automatically.
- Typing **`kimiko`** inside a Kimi CLI session triggers the authorization flow and capability announcement.

**Nothing personal is included.** There are no OAuth tokens, device IDs, session histories, logs, or backups in this repo.

---

## Prerequisites

### macOS

- macOS (Darwin/BSD tools)
- `make` (ships with macOS)
- Python 3.11+ (only if running validator tests/schemas)

### Linux / WSL

- Linux distribution (Ubuntu recommended for WSL)
- `make`, `python3`, standard POSIX tools

### Git Bash (Windows)

- [Git for Windows](https://git-scm.com/download/win)
- `make` (install via `choco install make` or MSYS2)
- Python 3.11+ (optional)

### PowerShell (Windows)

- PowerShell 7+ (`pwsh`)
- Python 3.11+ (optional)

---

## Quick Start

### macOS / Linux / WSL

```bash
# 1. Clone the repo
git clone https://github.com/spearchucker667/kimiko.git
cd kimiko

# 2. Run the installer
make install

# 3. Source the mandate activation (or add to ~/.zshrc / ~/.bashrc)
source ~/.kimi/activate-mandate.sh

# 4. Launch Kimi with the mandate wrapper
~/.kimi/launch-with-mandate.sh

# 5. Inside the CLI, enter the activation word
kimiko
```

### Git Bash (Windows)

```bash
# Same as macOS/Linux above
git clone https://github.com/spearchucker667/kimiko.git
cd kimiko
make install
source ~/.kimi/activate-mandate.sh
~/.kimi/launch-with-mandate.sh
```

> **Note**: Git Bash emulates `chmod` on NTFS. Actual file permissions are not enforced. See [`docs/INSTALL-WINDOWS.md`](docs/INSTALL-WINDOWS.md) for ACL guidance.

### PowerShell (Windows)

```powershell
# 1. Clone the repo
git clone https://github.com/spearchucker667/kimiko.git
cd kimiko

# 2. Install (platform-aware)
make install

# 3. Load the mandate activation
. $env:USERPROFILE\.kimi\activate-mandate.ps1

# 4. Launch Kimi with the mandate wrapper
& $env:USERPROFILE\.kimi\launch-with-mandate.ps1
```

> **Note**: You may need to run `Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser` first.

After step 5 (or the PowerShell equivalent) you should see the mandate acknowledgment and capability announcement identical to the original configuration.

> **Tip:** For a deep-dive into the mandate architecture, configuration layers, and troubleshooting, see [`docs/AGENTS.md`](docs/AGENTS.md).
>
> **Tip:** For detailed Windows installation walkthroughs, see [`docs/INSTALL-WINDOWS.md`](docs/INSTALL-WINDOWS.md).
>
> **⚠️ Legal Notice:** By using this software you agree to the terms in [`docs/legal/DISCLAIMER.md`](docs/legal/DISCLAIMER.md). Read it before proceeding.

---

## Makefile Targets

| Target | Description |
|---|---|
| `make install` | Platform-aware install (auto-detects OS) |
| `make install-windows` | PowerShell install into `%USERPROFILE%\.kimi` |
| `make install-gitbash` | Git Bash install (chmod is no-op on NTFS) |
| `make install-wsl` | WSL install (native Linux filesystem) |
| `make install-macos` | macOS install (BSD make, chmod enforced) |
| `make install-linux` | Native Linux install |
| `make verify` | Checks that all expected files exist, the validator directory is present, `kimiko` references are intact, and `kimi.json` is valid JSON |
| `make check` | Validates repo config files with the validator (structural + zero-blocker compliance) |
| `make sync` | Verifies `config.toml` ↔ `kimi.toml` and mandate YAML mirror files are byte-for-byte identical |
| `make test` | Runs the validator pytest suite |
| `make uninstall` | Removes only the files installed by Kimiko. **Does not touch** `credentials/`, `logs/`, `sessions/`, `telemetry/`, `user-history/`, or any other user secrets |
| `make permissions` | Shows Windows ACL guidance (Windows / Git Bash) |
| `make help` | Shows available targets and detected platform |

---

## Repository Layout

```
kimiko/
├── .github/
│   ├── CODEOWNERS
│   ├── ISSUE_TEMPLATE/
│   ├── dependabot.yml
│   ├── pull_request_template.md
│   └── workflows/
│       └── ci.yml
├── config/
│   ├── config.toml
│   ├── kimi.toml
│   ├── kimi.json.template
│   ├── latest_version.txt
│   ├── mandate-agent.yaml
│   └── mandate-kimiko-agent.yaml
├── docs/
│   ├── AGENTS.md
│   ├── CHANGELOG.md
│   ├── CODE_OF_CONDUCT.md
│   ├── CONTRIBUTING.md
│   ├── INSTALL-GITBASH.md      ← Git Bash guide
│   ├── INSTALL-WINDOWS.md      ← Windows install guide
│   ├── INSTALL-WSL.md          ← WSL guide
│   ├── legal/
│   │   └── DISCLAIMER.md
│   ├── README.md
│   ├── RUP.md
│   ├── SECURITY.md
│   ├── TODO.md
│   └── TROUBLESHOOTING.md      ← Platform-specific troubleshooting
├── scripts/
│   ├── activate-mandate.sh
│   ├── activate-mandate.ps1    ← PowerShell
│   ├── kimi-wrapper.sh
│   ├── kimi-wrapper.ps1        ← PowerShell
│   ├── kimi-shell-integration.sh
│   ├── kimi-shell-integration.ps1  ← PowerShell
│   ├── launch-with-mandate.sh
│   └── launch-with-mandate.ps1     ← PowerShell
├── validator/
│   ├── Makefile
│   ├── README.md
│   ├── validate_kimi.py
│   ├── schemas/
│   │   ├── config-schema.json
│   │   ├── config-zero-blocker-schema.json
│   │   ├── credentials-schema.json
│   │   ├── kimi-json-schema.json
│   │   ├── mandate-schema.json
│   │   └── mandate-zero-blocker-schema.json
│   └── tests/
│       ├── test_validator.py
│       ├── test_install_integration.py
│       └── fixtures/
├── .pre-commit-config.yaml
├── LICENSE
├── Makefile
└── README.md
```

## Directory Structure Created (in `~/.kimi`)

### macOS / Linux / WSL

```
~/.kimi/
├── config.toml
├── kimi.toml
├── kimi.json          ← rendered from template
├── activate-mandate.sh
├── kimi-shell-integration.sh
├── kimi-wrapper.sh
├── launch-with-mandate.sh
├── latest_version.txt
├── mandate-agent.yaml
├── mandate-kimiko-agent.yaml
└── validator/
    └── ...
```

### Windows (PowerShell)

```
%USERPROFILE%\.kimi\
├── config.toml
├── kimi.toml
├── kimi.json
├── activate-mandate.ps1
├── kimi-shell-integration.ps1
├── kimi-wrapper.ps1
├── launch-with-mandate.ps1
├── activate-mandate.sh      ← also available for Git Bash
├── kimi-wrapper.sh
├── launch-with-mandate.sh
├── latest_version.txt
├── mandate-agent.yaml
├── mandate-kimiko-agent.yaml
└── validator\
    └── ...
```

---

## Platform Notes

### macOS
- Full feature parity. BSD `make`, real `chmod`, native paths.
- All validator tests pass.

### Linux / WSL
- Full feature parity. GNU `make`, real `chmod`, native paths.
- WSL recommended over Git Bash for developers who want real Unix behavior on Windows.
- Install in WSL home (`~/.kimi`) rather than `/mnt/c/` for proper permission support.

### Git Bash
- `.sh` scripts work with caveats.
- `chmod` is emulated (no-op on NTFS). Use Windows ACLs for actual security.
- Line endings may need `dos2unix` if cloned with `core.autocrlf=true`.

### PowerShell
- Native `.ps1` scripts provided.
- No `make` required (but `make install-windows` works if make is installed).
- NTFS ACLs replace Unix permissions. Run `make permissions` for guidance.
- PowerShell execution policy must allow script execution.

---

## Security & Privacy Notes

- **No credentials are included.** You must authenticate the Kimi CLI yourself via its normal OAuth flow.
- `kimi.json` is generated from a template during `make install`; it contains only placeholder paths for your home directory.
- If you previously had a `~/.kimi/credentials/` directory, `make uninstall` will **not** remove it.
- On Windows, use Explorer Properties → Security or `icacls` to verify ACLs on sensitive files.

---

## Validator

The included `validator/` tool can sanity-check your `~/.kimi` installation:

```bash
# macOS / Linux / WSL / Git Bash
cd ~/.kimi/validator
make validate        # Full validation
make test            # pytest suite
make validate-config # config.toml only
make validate-mandates # mandate YAML files
make security        # Security checks only
make compliance      # Zero-blocker compliance checks
make lint            # Python linter (ruff)
```

```powershell
# PowerShell
cd $env:USERPROFILE\.kimi\validator
python -m pytest tests/ -v
python validate_kimi.py all $env:USERPROFILE\.kimi
python validate_kimi.py compliance $env:USERPROFILE\.kimi
```

---

## Customization

Before running `make install`, you may want to edit these placeholders in the copied files:

- `config/config.toml` and `config/kimi.toml`: replace `<YOUR_USERNAME>` and `<YOUR_PERSONA_UUID>` under `[system_status.kimi_ai_persona]`.
- `config/kimi.json.template`: the Makefile automatically substitutes `<YOUR_HOME_DIR>` with your actual `$HOME` (or `%USERPROFILE%` on Windows).

---

## License

See [LICENSE](LICENSE).
