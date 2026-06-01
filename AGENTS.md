# AGENTS.md — Kimiko Project Operational Guide

> This file is the authoritative guide for AI coding agents working on the **Kimiko** repository.
> Kimiko is a cross-platform configuration-management repository that packages the reproducible parts of a `~/.kimi` directory for the [Kimi Code CLI](https://www.moonshot.cn/) by MoonshotAI.
> It is **not** a traditional application codebase. There is no `pyproject.toml`, `package.json`, or `Cargo.toml` at the root.
> The only buildable code is the standalone Python CLI under `validator/`.

---

## Project Overview

| Property | Value |
|---|---|
| **Name** | Kimiko |
| **Purpose** | Cross-platform installer and validator for the Kimi Code CLI `~/.kimi` mandate configuration |
| **Platforms** | macOS, Linux, WSL, Git Bash (Windows), PowerShell (Windows) |
| **CLI Version** | 1.46.0 (cached in `config/latest_version.txt`) |
| **Runtime Target** | Python 3.13 package `kimi-cli` (installed via `uv` into `~/.local/share/uv/tools/kimi-cli/`) |
| **Primary Languages** | TOML, YAML, Bash, PowerShell, Python, JSON |
| **License** | See `LICENSE` at repository root |

This repository stores:
- Runtime configuration (`config.toml`, `kimi.toml`)
- System agent mandate specifications (`mandate-agent.yaml`, `mandate-kimiko-agent.yaml`)
- Shell integration scripts (`.sh` and `.ps1` pairs)
- A configuration validator tool (`validator/`)
- Documentation (`docs/`)

The installed `~/.kimi` directory also holds OAuth credentials, session data, logs, and telemetry created by the Kimi CLI at runtime. These are **not** committed to the repository.

---

## Technology Stack

| Layer | Technology | Notes |
|---|---|---|
| **Application Runtime** | Python 3.13 `kimi-cli` | Installed via `uv`; source lives in site-packages, not this repo |
| **Config Formats** | TOML (primary), YAML (agent specs), JSON (schemas, registry) | |
| **Build Tool** | GNU/BSD `make` | Root `Makefile` handles cross-platform install/validation |
| **Validator** | Python 3.11+ | Uses built-in `tomllib`; `jsonschema`, `pyyaml`, `pytest`, `ruff` |
| **Schema Standard** | JSON Schema Draft 2020-12 | 6 schema files under `validator/schemas/` |
| **CI/CD** | GitHub Actions | `.github/workflows/ci.yml` |
| **Pre-commit** | `pre-commit` framework | `.pre-commit-config.yaml` with `ruff` and generic hooks |
| **Dependency Updates** | Dependabot v2 | Configured in `.github/dependabot.yml` |

---

## Directory Layout

### Repository source layout

```
kimiko/
├── Makefile                    # Root cross-platform installer & validator driver
├── README.md                   # Human-facing project overview
├── LICENSE                     # License file
├── .gitignore                  # Git ignore rules
├── .gitattributes              # Git attributes
├── .pre-commit-config.yaml     # Pre-commit hooks configuration
├── config/                     # Maps to ~/.kimi root when installed
│   ├── config.toml             # Primary runtime configuration (~1,483 lines)
│   ├── kimi.toml               # Hardened mirror of config.toml
│   ├── kimi.json.template      # Template for work-directory registry
│   ├── latest_version.txt      # Cached CLI version string ("1.46.0")
│   ├── mandate-agent.yaml      # System agent spec
│   └── mandate-kimiko-agent.yaml  # Hardened mirror of mandate-agent.yaml
├── scripts/                    # Maps to ~/.kimi root when installed
│   ├── activate-mandate.sh     # Mandate env var exporter + verifier
│   ├── activate-mandate.ps1    # PowerShell equivalent
│   ├── kimi-wrapper.sh         # KIMI binary wrapper (--yolo enforcement)
│   ├── kimi-wrapper.ps1        # PowerShell equivalent
│   ├── kimi-shell-integration.sh   # Shell profile integration
│   ├── kimi-shell-integration.ps1  # PowerShell equivalent
│   ├── launch-with-mandate.sh  # Banner launcher
│   ├── launch-with-mandate.ps1 # PowerShell equivalent
│   ├── INSTALL-GITBASH.md      # Git Bash-specific install guide
│   └── INSTALL-WSL.md          # WSL-specific install guide
├── docs/                       # Documentation
│   ├── AGENTS.md               # This file (installed to ~/.kimi/AGENTS.md)
│   ├── ARCHITECTURE.md         # Architecture Decision Records (ADRs)
│   ├── CHANGELOG.md            # Keep-a-Changelog format
│   ├── CONTRIBUTING.md         # Contribution guidelines
│   ├── CODE_OF_CONDUCT.md      # Contributor Covenant v2.1
│   ├── INSTALL-WINDOWS.md      # Windows installation guide
│   ├── RUP.md                  # Repository Upgrade Protocol
│   ├── SECURITY.md             # Security policy & reporting
│   ├── TODO.md                 # Bug hunt tracker
│   ├── TROUBLESHOOTING.md      # Platform-specific troubleshooting
│   └── legal/
│       └── DISCLAIMER.md       # Binding liability waiver
├── validator/                  # Only buildable code project
│   ├── Makefile                # Validator subproject automation
│   ├── README.md               # Validator documentation
│   ├── requirements.txt        # Python dependencies
│   ├── validate_kimi.py        # Main CLI entry point (~633 lines)
│   ├── schemas/                # JSON Schema files (Draft 2020-12)
│   │   ├── config-schema.json
│   │   ├── config-zero-blocker-schema.json
│   │   ├── credentials-schema.json
│   │   ├── kimi-json-schema.json
│   │   ├── mandate-schema.json
│   │   └── mandate-zero-blocker-schema.json
│   └── tests/
│       ├── test_validator.py              # Core pytest suite (~487 lines)
│       ├── test_install_integration.py    # Makefile integration tests
│       └── fixtures/                      # Negative test fixtures
│           ├── bad-config-no-admin.toml
│           ├── bad-config-no-yolo.toml
│           ├── bad-mandate-missing-tools.yaml
│           └── bad-mandate-no-zero-blockers.yaml
└── .github/
    ├── workflows/ci.yml            # GitHub Actions CI
    ├── dependabot.yml              # Dependabot configuration
    ├── CODEOWNERS                  # Code ownership
    ├── pull_request_template.md    # PR template
    └── ISSUE_TEMPLATE/
        ├── bug_report.md
        └── feature_request.md
```

### Installed `~/.kimi` directory

After `make install`, the following are placed in `~/.kimi` (or `%USERPROFILE%\.kimi` on Windows):
- All flat files from `config/` (rendering `kimi.json.template` into `kimi.json`)
- All scripts from `scripts/`
- The full `validator/` subtree
- Runtime-created directories: `credentials/`, `logs/`, `sessions/`, `telemetry/`, `user-history/`, `plans/`, `.backups/`

---

## Build and Test Commands

### Root Makefile (repository root)

The root `Makefile` is the primary entry point for installation and validation. It auto-detects the platform.

```bash
# Show available targets and detected platform
make help

# Platform-aware install (auto-detects OS)
make install

# Platform-specific installs
make install-windows    # PowerShell → %USERPROFILE%\.kimi
make install-gitbash    # Git Bash (MINGW/MSYS)
make install-wsl        # WSL (native ext4 filesystem)
make install-macos      # macOS (BSD make, chmod enforced)
make install-linux      # Native Linux

# Validate source configs in repo (structural + advisory compliance)
make check

# Verify config.toml ↔ kimi.toml and mandate YAML mirrors are in sync
make sync

# Run pytest suite for the validator
make test

# Install + verify files present, JSON valid, mandate_code present
make verify

# Remove installed Kimiko files (preserves credentials/, logs/, sessions/)
make uninstall

# Show Windows ACL guidance
make permissions
```

**Platform Matrix for Root Makefile Targets:**

| Target | macOS | Linux | WSL | Git Bash | PowerShell |
|---|---|---|---|---|---|
| `install` | ✓ | ✓ | ✓ | ✓ | ✓ |
| `check` | ✓ | ✓ | ✓ | ✓ | ✗ (error) |
| `sync` | ✓ | ✓ | ✓ | ✓ | ✗ (error) |
| `test` | ✓ | ✓ | ✓ | ✓ | ✗ (error) |
| `verify` | ✓ | ✓ | ✓ | ✓ | ✓ |
| `uninstall` | ✓ | ✓ | ✓ | ✓ | ✗ (shows PS command) |
| `permissions` | info | info | info | info | icacls guidance |

### Validator Subproject (`validator/`)

```bash
cd validator

# Run everything (validate + test)
make all

# Run pytest suite
make test

# Validate installed ~/.kimi directory
make validate

# Validate individual file types
make validate-config      # config.toml / kimi.toml
make validate-registry    # kimi.json
make validate-mandates    # mandate YAML files
make validate-credentials # credentials JSON

# Security sweep (permissions + secret scanning)
make security

# Zero-blocker Mandate kimiko compliance
make compliance

# Python linter
make lint
```

### Direct Python Invocation

```bash
cd validator

# Validate entire .kimi directory
python validate_kimi.py all ~/.kimi

# Validate zero-blocker compliance
python validate_kimi.py compliance ~/.kimi

# Individual file types
python validate_kimi.py config ~/.kimi/config.toml
python validate_kimi.py registry ~/.kimi/kimi.json
python validate_kimi.py mandate ~/.kimi/mandate-agent.yaml
python validate_kimi.py credentials ~/.kimi/credentials/kimi-code.json
python validate_kimi.py security ~/.kimi
```

**Exit codes:** `0` = pass, `1` = validation errors, `2` = usage error.

---

## CI/CD

GitHub Actions workflow: `.github/workflows/ci.yml`

**Triggers:** `push` and `pull_request` to `main` / `master`.

**Jobs:**
1. **`test-macos`** — Installs Python 3.13, installs deps, runs pytest, runs ruff, runs `make install`, `make verify`, `make sync`, and compliance check.
2. **`test-ubuntu`** — Same as macOS but runs `make check` (structural + compliance validation).
3. **`test-windows-pwsh`** — Runs on `windows-latest` with `shell: pwsh`. Installs deps, runs pytest, installs via `make install-windows`, validates PowerShell syntax with `PSParser`, verifies files exist, validates `kimi.json` JSON, verifies `kimiko` references with strict regex, and performs PowerShell-native sync checks.
4. **`test-windows-gitbash`** — Runs on `windows-latest` with `shell: bash`. Installs deps, runs pytest, runs `make install`, `make verify`, `make sync`, and `make check`.

**Dependabot:** Configured in `.github/dependabot.yml` to scan `/validator` (pip) and root `/` (GitHub Actions) weekly.

---

## Code Style Guidelines

### Python (Validator)

- **Language**: Python 3.11+ (uses built-in `tomllib`; for 3.10 or earlier install `tomli`)
- **Style**: PEP 8; run `ruff check validate_kimi.py tests/`
- **Typing**: Use type hints (`typing.Any`, `Dict`, `List`, `Optional`, `Tuple`)
- **String formatting**: f-strings preferred
- **Error handling**: Explicit exception handling with informative messages
- **Color output**: ANSI colors wrapped in a `C` class and gated behind `sys.stdout.isatty()`
- **Cross-platform paths**: Use `pathlib.Path`; gate platform-specific code with `platform.system()`
- **File permissions**: Sensitive files expected to be `0o600` on Unix; skipped on Windows

### Bash Scripts (`scripts/*.sh`)

- Shebang: `#!/bin/bash`
- Use `set -euo pipefail` where appropriate
- Use `${HOME}` for portability; never hardcode `/home/username`
- Reference `~/.kimi/` or `${HOME}/.kimi/` directly; no `/global/` indirections
- The `kimi-wrapper.sh` must always pass `--yolo`

### PowerShell Scripts (`scripts/*.ps1`)

- Use `#` comments
- Set `$ErrorActionPreference = "Stop"` at script start
- Use `$env:USERPROFILE` for home-directory paths on Windows
- Define functions with `global:` prefix when they must persist in the session

### TOML (`config/*.toml`)

- Prefer section headers over inline tables for readability
- Keep `config.toml` and `kimi.toml` synchronized at all times
- All keys, comments, and documentation are in **English**

### YAML (`config/mandate-*.yaml`)

- Use 2-space indentation
- Keep `mandate-agent.yaml` and `mandate-kimiko-agent.yaml` synchronized at all times

### JSON (`validator/schemas/*.json`, `config/kimi.json.template`)

- Use 2-space indentation
- All schemas use JSON Schema Draft 2020-12

### Commit Messages

Prefix with the area changed:
- `config:` — TOML configuration changes
- `validator:` — Python validation logic
- `scripts:` — Shell or PowerShell scripts
- `docs:` — Documentation updates
- `ci:` — GitHub Actions or CI configuration

---

## Testing Instructions

### Running Tests

```bash
# macOS / Linux / WSL / Git Bash
cd validator
python3 -m pytest tests/ -v

# PowerShell
cd $env:USERPROFILE\kimiko\validator
python -m pytest tests/ -v
```

### Test Files

- **`tests/test_validator.py`** (~487 lines) — Core unit tests covering:
  - Schema loading (`TestSchemaLoading`)
  - Config validation (`TestConfigValidation`)
  - Registry validation (`TestRegistryValidation`)
  - Credentials validation (`TestCredentialsValidation`)
  - Security checks — file permissions and secret scanning (`TestSecurityChecks`)
  - Security command (`TestSecurityCommand`)
  - Mandate validation (`TestMandateValidation`)
  - Schema meta-validation (`TestSchemaMetaValidation`)
  - Compliance / zero-blocker validation (`TestComplianceValidation`)
  - Fixture file regression tests (`TestFixtureFiles`)
  - Mandate path validation (`TestMandatePaths`)
  - End-to-end `cmd_all()` (`TestAllCommand`)

- **`tests/test_install_integration.py`** (~126 lines) — Makefile integration tests:
  - `test_make_install_creates_expected_files` — regression for BUG-013
  - `test_make_install_windows_creates_ps1_files` — regression for BUG-005
  - `test_make_install_windows_uses_userprofile_when_home_unset` — regression for BUG-020
  - `test_make_uninstall_preserves_credentials` — ensures uninstall does not delete user-created `credentials/`

- **`tests/fixtures/`** — Negative test fixtures for schema regression testing.

### Adding New Tests

1. Add unit tests in `tests/test_validator.py` using `pytest`.
2. Group tests by feature using classes (e.g., `TestSecurityChecks`).
3. Use `tmp_path` fixtures for filesystem-dependent tests.
4. Import from `validate_kimi.py` directly; `sys.path` is adjusted at the top of the test file.
5. Use `@pytest.mark.skipif` for platform-specific behavior (Windows vs. Unix permissions).

### Pre-commit Hooks

Install locally:
```bash
pip install pre-commit
pre-commit install
```

Hooks run on every commit:
- `trailing-whitespace`, `end-of-file-fixer`, `check-yaml`, `check-added-large-files` (max 1000 KB), `check-merge-conflict`, `check-symlinks`, `detect-private-key`
- `ruff` lint + format on `validator/*.py` files

---

## Security Considerations

### Sensitive Files

- `credentials/kimi-code.json` contains live OAuth tokens. Treat it as a secret.
- `config.toml` contains API endpoint URLs and mandate authorization metadata.
- On Unix-like systems, sensitive files should have mode `0o600`.
- On Windows/Git Bash, `chmod` is emulated on NTFS and does not enforce actual permissions. Use Windows Explorer ACLs or `icacls`.

### Validator Security Checks

The validator performs three categories of security checks:
1. **Credential file permissions** — Ensures credential files and `device_id` are not world-readable (`0o600`). Skipped on Windows.
2. **Secret scanning** — Heuristically scans non-credential files for leaked API keys (`sk-...`), JWTs, hardcoded passwords/tokens, and hex patterns near secret context words. Files > 1 MiB are skipped; max scan depth = 3.
3. **AGENTS.md presence** — Ensures the directory has agent guidance.

### `.gitignore` Protections

The root `.gitignore` excludes:
- `credentials/`, `device_id`, `kimi.json`, `logs/`, `sessions/`, `telemetry/`, `plans/`, `.backups/`
- `__pycache__/`, `.pytest_cache/`, `.ruff_cache/`

Never commit credentials or session data.

### Pre-commit `detect-private-key`

The pre-commit hook scans for private keys in commits. This is a last-line defense; never stage secrets.

### Security Policy

- Only the latest `main` branch is supported.
- Report vulnerabilities privately to `@spearchucker667` on GitHub.
- See `docs/SECURITY.md` for full policy.

---

## Architecture

### Four-Layer Mandate Enforcement Mesh

This repository implements a four-layer enforcement mesh (ADR-004). No single file operates in isolation.

1. **Primary Runtime Config** (`config.toml`) — Live configuration loaded by the CLI on every startup.
2. **Mirror Config** (`kimi.toml`) — Byte-for-byte hardened mirror (plus comment header). Serves as a fallback if `config.toml` is corrupted.
3. **Mandate Agent Specs** (`mandate-agent.yaml`, `mandate-kimiko-agent.yaml`) — YAML agent specifications that inject the zero-blocker system prompt into every session.
4. **Shell Integration** (`*.sh`, `*.ps1`) — Enforces mandate at the OS shell level before the CLI even starts.

### Shell Script Interlock Chain

```
launch-with-mandate.sh       # Prints banner → calls kimi-wrapper.sh
    ↓
kimi-wrapper.sh              # Exports KIMI_MANDATE_ACTIVE → execs kimi with --config-file, --agent-file, --yolo
    ↓
CLI reads config.toml        # [entry_protocol] activates kimiko
    ↓
CLI loads mandate-kimiko-agent.yaml   # system prompt → zero blockers
```

There are also `kimi-shell-integration.sh` and `activate-mandate.sh` for profile-level integration:
- `activate-mandate.sh` is the baseline: exports env vars and defines minimal `kimi()` / `kimi-maestro()` functions.
- `kimi-shell-integration.sh` sources `activate-mandate.sh`, then redefines `kimi()` / `kimi-maestro()` with more explicit flag passing, plus `kimi-status()`.
- All PowerShell equivalents follow the same hierarchy with `global:` function prefixes.

### Key Architecture Decisions

See `docs/ARCHITECTURE.md` for full ADRs. Summaries:

- **ADR-001:** Mirror config files (`config.toml` ↔ `kimi.toml`) for mandate persistence.
- **ADR-002:** WSL detection via `uname -r` string matching.
- **ADR-003:** Exit code aggregation via `max()` instead of bitwise OR.
- **ADR-004:** Four-layer mandate enforcement mesh.
- **ADR-005:** Platform-gated Makefile targets with auto-detection.
- **ADR-006:** `HOME_FWD` / `USERPROFILE` pre-computation for Windows template substitution.
- **ADR-007:** Validator schema hierarchy — dual schemas per config type (structural vs. zero-blocker compliance).
- **ADR-008:** Non-blocking compliance in `make check` (`|| true` advisory check during development).

### Validator Schema Hierarchy

| Schema | Purpose | `additionalProperties` |
|---|---|---|
| `config-schema.json` | Structural validation | `true` |
| `config-zero-blocker-schema.json` | Mandate compliance | `true` (validates critical subset only) |
| `mandate-schema.json` | Structural validation | `false` |
| `mandate-zero-blocker-schema.json` | Mandate compliance | `false` |

---

## Development Conventions

### Synchronization Requirement (Hard Rule)

- If you modify `config/config.toml`, you **must** apply the identical change to `config/kimi.toml`.
- If you modify `config/mandate-agent.yaml`, you **must** apply the identical change to `config/mandate-kimiko-agent.yaml`.
- PRs that introduce drift between these file pairs will be rejected.
- Use `make sync` to verify byte-for-byte identity before committing.

### Path Conventions

- Shell scripts must reference `~/.kimi/` or `${HOME}/.kimi/` paths.
- Never use `~/Downloads/`, `~/.kimi/global/`, or other indirect paths.
- The `kimi-wrapper.sh` script must always pass `--yolo`.

### Contributing Workflow

1. Fork and create a feature branch.
2. Make changes following the style guidelines above.
3. Run validation:
   ```bash
   make check
   make test
   make sync
   ```
4. Open a Pull Request using the template in `.github/pull_request_template.md`.
5. Ensure CI passes on macOS, Ubuntu, and both Windows variants.

See `docs/CONTRIBUTING.md` for full details.

---

## Deployment / Installation Process

The root `Makefile` is the deployment engine. It does not compile code; it copies files and sets permissions.

1. **Platform detection** at parse time (`uname -s`, `uname -r`, `OS=Windows_NT`).
2. **File copy** from `config/` and `scripts/` into `~/.kimi/` (or `%USERPROFILE%\.kimi`).
3. **Template rendering** — `kimi.json.template` has `<YOUR_HOME_DIR>` substituted with the detected home directory.
4. **Permission setting** — On macOS/Linux/WSL, config files get `chmod 600` and scripts get `chmod +x`. On Windows/Git Bash, this is skipped (NTFS ACLs are recommended).
5. **Validator installation** — Full `validator/` subtree is copied into `~/.kimi/validator/`.

Uninstall (`make uninstall`) removes only managed files. It **preserves** `credentials/`, `logs/`, `sessions/`, and any user-created files.

---

## Troubleshooting

### Validation Fails on `mandate-agent.yaml`
**Cause:** `system_prompt_path` or `config_file` uses absolute paths that the validator cannot resolve.
**Fix:** Use relative paths:
```yaml
system_prompt_path: mandate-kimiko-agent.yaml
config_file: config.toml
```

### `config.toml` and `kimi.toml` Drift
**Cause:** One file was edited without mirroring.
**Fix:** Copy `config.toml` to `kimi.toml`, then re-add the `kimi.toml` comment header. Run `make sync`.

### Stale Python Cache
**Cause:** `.pyc` files contain outdated compiled code.
**Fix:**
```bash
find validator -name '__pycache__' -exec rm -rf {} +
find validator -name '*.pyc' -delete
```

### "Invalid tools" Error
**Cause:** Mandate YAML contains tool identifiers that do not match the CLI's internal tool registry.
**Fix:** Update the `tools` array in both mandate YAMLs to use official CLI tool paths (format: `kimi_cli.tools.<module>:<ClassName>`).

### Platform-specific Issues
See `docs/TROUBLESHOOTING.md` for detailed guidance on:
- macOS: `make` issues, BSD vs GNU tool differences
- Git Bash: `chmod` emulation, line endings, symbolic links
- WSL: clock drift, filesystem recommendations (use native `ext4`, not `/mnt/c/...`)
- PowerShell: execution policy, `icacls` for permissions
- Validator: missing Python dependencies, schema loading failures

---

## Language

All comments, configuration keys, log messages, documentation, and code in this repository are in **English**.

---

## How to Interact with This Repository

- **Modify configuration:** Edit `config/config.toml` directly. Always mirror changes to `config/kimi.toml`.
- **Modify mandate specs:** Edit `config/mandate-agent.yaml`. Always mirror changes to `config/mandate-kimiko-agent.yaml`.
- **Modify scripts:** Edit files in `scripts/`. Maintain `.sh` / `.ps1` pairs for cross-platform parity.
- **Modify validator:** Edit `validator/validate_kimi.py` and add tests in `validator/tests/test_validator.py`.
- **Validate changes:** Run `make check`, `make test`, and `make sync` before committing.
- **Run compliance:** `cd validator && python validate_kimi.py compliance ../config` (against repo sources) or `python validate_kimi.py compliance ~/.kimi` (against installed files).
- **Backups:** Create dated backups in `.backups/` before making significant config changes.
