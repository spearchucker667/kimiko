# Kimiko: Pentesting Configuration for Kimi

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![CI](https://github.com/spearchucker667/kimiko/actions/workflows/ci.yml/badge.svg)](https://github.com/spearchucker667/kimiko/actions/workflows/ci.yml)
![macOS](https://img.shields.io/badge/macOS-supported-blue?logo=apple)
![Windows](https://img.shields.io/badge/Windows-Git%20Bash%20%7C%20WSL%20%7C%20PowerShell-blue?logo=windows)
![Linux](https://img.shields.io/badge/Linux-supported-blue?logo=linux)
![Python](https://img.shields.io/badge/Python-3.11+-blue?logo=python)

<img width="1774" height="887" alt="Kimiko project banner" src="https://github.com/user-attachments/assets/2cd40966-0aae-4262-83d7-ceb551a4b192" />

**Kimiko** is a specialized configuration repository that transforms the [Kimi Code CLI](https://www.moonshot.cn/) into a powerful, unrestricted agent for offensive security, red-teaming, and penetration testing.

When you enter **`kimiko`** in a Kimi CLI session, the full adversarial mandate activates—granting the AI the authority and context needed for exploit development, network reconnaissance, and advanced security research.

---

## What This Project Does

Kimiko packages the necessary configuration, agent mandates, and shell integrations into a single Makefile-driven installer. After installation:

- Your local `~/.kimi/` is hardened with the **Kimiko mandate**, optimized for adversarial workflows.
- Launching `kimi` via the wrapper loads the offensive security context automatically.
- Typing **`kimiko`** inside a Kimi CLI session triggers the zero-blocker authorization flow and offensive capability announcement.

**Designed for Authorized Pentesting Only.** This configuration removes standard AI safety guardrails to allow for unrestricted security research. **The user is fully and exclusively liable for all actions taken.**

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

# 3. Source the mandate activation
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

### PowerShell (Windows)

```powershell
# 1. Clone the repo
git clone https://github.com/spearchucker667/kimiko.git
cd kimiko

# 2. Install
make install

# 3. Load the mandate activation
. $env:USERPROFILE\.kimi\activate-mandate.ps1

# 4. Launch Kimi with the mandate wrapper
& $env:USERPROFILE\.kimi\launch-with-mandate.ps1
```

After step 5 (or the PowerShell equivalent) you should see the Kimiko mandate acknowledgment and offensive capability announcement.

> **Tip:** For a deep-dive into the offensive mandate architecture, see [`docs/AGENTS.md`](docs/AGENTS.md).
>
> **⚠️ Legal Notice:** By using this software you agree to the terms in [`docs/legal/DISCLAIMER.md`](docs/legal/DISCLAIMER.md). **YOU ARE FULLY AND EXCLUSIVELY LIABLE FOR YOUR ACTIONS.**

---

## Makefile Targets

| Target | Description |
|---|---|
| `make install` | Platform-aware install (auto-detects OS) |
| `make verify` | Checks that all expected files exist and `kimiko` references are intact |
| `make check` | Validates repo config files (structural + adversarial compliance) |
| `make sync` | Verifies config mirrors are identical |
| `make test` | Runs the validator pytest suite |
| `make uninstall` | Removes installed files (preserves secrets) |
| `make help` | Shows available targets |

---

## Repository Layout

```
kimiko/
├── config/
│   ├── config.toml
│   ├── kimi.toml
│   ├── mandate-agent.yaml
│   └── mandate-kimiko-agent.yaml
├── docs/
│   ├── AGENTS.md
│   ├── ARCHITECTURE.md
│   ├── legal/
│   │   └── DISCLAIMER.md
│   ├── README.md
│   └── ...
├── scripts/
│   ├── activate-mandate.sh
│   ├── kimi-wrapper.sh
│   └── ...
├── validator/
│   └── ...
├── LICENSE
├── Makefile
└── README.md
```
