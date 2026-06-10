# Kimiko: Pentesting Configuration for Kimi

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![CI](https://github.com/spearchucker667/kimiko/actions/workflows/ci.yml/badge.svg)](https://github.com/spearchucker667/kimiko/actions/workflows/ci.yml)
![macOS](https://img.shields.io/badge/macOS-supported-blue?logo=apple)
![Windows](https://img.shields.io/badge/Windows-Git%20Bash%20%7C%20WSL%20%7C%20PowerShell-blue?logo=windows)
![Linux](https://img.shields.io/badge/Linux-supported-blue?logo=linux)
![Python](https://img.shields.io/badge/Python-3.11+-blue?logo=python)

<p align="center">
  <video
    src="https://github.com/user-attachments/assets/28f2cfb4-cb4c-4370-8ab4-2c8a2f6d1a42"
    controls
    width="900"
  ></video>
</p>

<p align="center">
  <img width="1774" height="887" alt="Kimiko project banner" src="https://github.com/user-attachments/assets/2cd40966-0aae-4262-83d7-ceb551a4b192" />
</p>

**Kimiko** is a specialized configuration repository that transforms the [Kimi Code CLI](https://www.moonshot.cn/) into a powerful agent configuration for authorized offensive security, red-teaming, and penetration-testing workflows.

When you enter **`kimiko`** in a Kimi CLI session, the Kimiko mandate activates, giving the AI the project-specific context needed for security research, audit support, exploit-analysis workflows, reconnaissance planning, and authorized penetration-testing operations.

---

## What This Project Does

Kimiko packages the necessary configuration, agent mandates, and shell integrations into a single Makefile-driven installer. After installation:

- Your local `~/.kimi/` is configured with the **Kimiko mandate**, optimized for authorized adversarial security workflows.
- Launching `kimi` via the wrapper loads the Kimiko security-research context automatically.
- Typing **`kimiko`** inside a Kimi CLI session triggers the mandate acknowledgment and capability announcement.

**Designed for Authorized Pentesting Only.** This configuration is intended for lawful security research, controlled red-team engagements, lab environments, and systems you own or are explicitly authorized to test. **The user is fully and exclusively liable for all actions taken.**

---

## Prerequisites

### macOS

- macOS with Darwin/BSD userland tools
- `make` — ships with macOS Command Line Tools
- Python 3.11+ — only required for validator tests and schemas

### Linux / WSL

- Linux distribution — Ubuntu recommended for WSL
- `make`
- `python3`
- Standard POSIX tools

### Git Bash on Windows

- [Git for Windows](https://git-scm.com/download/win)
- `make` — install via Chocolatey, MSYS2, or another package manager
- Python 3.11+ — optional unless running validators/tests

### PowerShell on Windows

- PowerShell 7+ (`pwsh`)
- Python 3.11+ — optional unless running validators/tests

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
````

### Git Bash on Windows

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

### PowerShell on Windows

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

# 5. Inside the CLI, enter the activation word
kimiko
```

After activation, you should see the Kimiko mandate acknowledgment and capability announcement.

> **Tip:** For a deep dive into the mandate architecture, see [`docs/AGENTS.md`](docs/AGENTS.md).
>
> **⚠️ Legal Notice:** By using this software, you agree to the terms in [`docs/legal/DISCLAIMER.md`](docs/legal/DISCLAIMER.md). **YOU ARE FULLY AND EXCLUSIVELY LIABLE FOR YOUR ACTIONS.**

---

## Makefile Targets

| Target           | Description                                                             |
| ---------------- | ----------------------------------------------------------------------- |
| `make install`   | Platform-aware install with automatic OS detection                      |
| `make verify`    | Checks that all expected files exist and `kimiko` references are intact |
| `make check`     | Validates repo configuration files for structural and policy compliance |
| `make sync`      | Verifies config mirrors are identical                                   |
| `make test`      | Runs the validator pytest suite                                         |
| `make uninstall` | Removes installed files while preserving secrets                        |
| `make help`      | Shows available targets                                                 |

---

## Repository Layout

```text
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

---

## Verification

Run the verification target after installation:

```bash
make verify
```

Run the full check suite:

```bash
make check
```

Run validator tests:

```bash
make test
```

---

## Uninstall

To remove installed Kimiko files while preserving secrets:

```bash
make uninstall
```

---

## Legal and Usage Boundaries

Kimiko is intended only for:

* Systems you own
* Systems you are explicitly authorized to test
* Internal lab environments
* Capture-the-flag and training environments
* Professional red-team and penetration-testing engagements with written authorization

Kimiko is not intended for unauthorized access, credential theft, malware deployment, persistence, evasion, extortion, or activity against third-party systems without permission.

Review the full disclaimer before use:

```text
docs/legal/DISCLAIMER.md
```

---

## License

This project is licensed under the MIT License. See [`LICENSE`](LICENSE).
