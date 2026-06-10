# Changelog

All notable changes to the Kimiko project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

### Added
- **Complete Windows port** supporting Git Bash, WSL, and PowerShell:
  - Four PowerShell scripts (`scripts/*.ps1`) with native Windows path handling.
  - Cross-platform `Makefile` with OS auto-detection (macOS, Linux, WSL, Git Bash, PowerShell).
  - `make install-windows`, `make install-gitbash`, `make install-wsl` platform-specific targets.
  - `make permissions` target providing Windows ACL guidance.
  - Multi-platform CI matrix testing `macos-latest`, `ubuntu-latest`, `windows-latest` (PowerShell + Git Bash).
- `docs/INSTALL-WINDOWS.md` — comprehensive Windows installation guide for all three environments.
- `docs/TROUBLESHOOTING.md` — platform-specific troubleshooting for macOS, Git Bash, WSL, and PowerShell.
- `docs/INSTALL-GITBASH.md` — Git Bash-specific installation notes and caveats.
- `docs/INSTALL-WSL.md` — WSL-specific installation notes and recommendations.
- Initial public-ready sanitized repository derived from private `~/.kimi-code` configuration.
- `.github/CODEOWNERS` defining ownership for all project areas.
- `docs/legal/DISCLAIMER.md` — extensive liability waiver with `inthewind exploit` classifier.
- `docs/CODE_OF_CONDUCT.md` — community code of conduct.
- `docs/SECURITY.md`, `docs/CONTRIBUTING.md`, and `docs/CHANGELOG.md`.
- `Makefile` with `install`, `verify`, `uninstall`, `check`, `sync`, `test`, and `help` targets (originally macOS-only, now cross-platform).
- `kimi.json.template` for dynamic home-path rendering at install time.
- `docs/AGENTS.md` comprehensive agent documentation covering mandate architecture, compliance, and troubleshooting.
- `docs/README.md` with quick-start guide, directory structure, and security notes.
- `.gitignore` covering macOS, Python, IDE, and Kimi runtime artifacts.
- `validator/requirements.txt` for dependency management.
- `validator/tests/fixtures/` with negative test cases for schema regression testing.
- `validator/tests/test_install_integration.py` for Makefile integration testing.
- `make check` and `make sync` targets for pre-install validation and drift detection.
- `SECURITY_SIZE_LIMIT` (1MB) in `cmd_security` to skip oversized files.

### Changed
- **Repository reorganized into logical subdirectories:**
  - `config/` — TOML configs, mandate YAMLs, and `kimi.json.template`
  - `scripts/` — Shell integration scripts
  - `docs/` — All documentation including `legal/DISCLAIMER.md`
  - `validator/` — Unchanged location (maps directly to `~/.kimi-code/validator/`)
- `Makefile` updated with explicit per-file install rules to support the new layout.
- All documentation cross-references updated to use subdirectory paths.
- Authorization code renamed from `262854` → `kimiko` across all configs, schemas, and documentation.
- Hardcoded `/Users/super_user/` paths replaced with portable `${HOME}` references in shell scripts.
- `author` and `uuid` fields in `config.toml` / `kimi.toml` neutralized to `<YOUR_USERNAME>` and `<YOUR_PERSONA_UUID>` placeholders.

### Fixed
- `launch-with-mandate.sh` no longer passes duplicate `--agent-file` to `kimi-wrapper.sh`.
- `AGENTS.md` troubleshooting example updated to reference `mandate-kimiko-agent.yaml`.
- `AGENTS.md` directory layout corrected to remove non-existent `tests/fixtures/` entry.
- `AGENTS.md` `kimi.json` description corrected (object, not array).
- `validator/tests/test_validator.py` cleaned up: replaced `__import__("sys")` hack with standard `import sys`.
- `activate-mandate.sh` and `launch-with-mandate.sh` now use `set -euo pipefail`.
- `kimi-wrapper.sh` now checks that the Kimi CLI binary exists before executing.
- `kimi-shell-integration.sh` now unsets any existing `kimi` function before redefining.
- `scan_for_secrets` regex narrowed to avoid false positives on git SHA hashes.
- `make check` compliance step is now a hard gate: removed `|| true` so zero-blocker violations fail the build.
- `make verify` grep pattern tightened for `mandate-kimiko-agent.yaml` (`mandate_code.*kimiko` instead of bare `kimiko`).
- `cmd_all` return-code aggregation changed from bitwise OR to `max()` for standard Unix exit-code semantics.
- `colorize()` now checks both `stdout.isatty()` and `stderr.isatty()`.
- `cmd_security` now scans `*.sh` and `*.ps1` files for secrets.
- `validator/Makefile` targets now check `~/.kimi-code` existence before running.
- CI matrix tightened: `test-ubuntu` now runs `make sync` and `make check`; PowerShell verification uses stricter `mandate_code` patterns.
- Pre-commit ruff version bumped from `v0.5.0` to `v0.15.15` to match `requirements.txt`.
- Unused imports removed from `validate_kimi.py` and test files (ruff clean).
- `activate-mandate.sh` and `activate-mandate.ps1` mandate verification patterns tightened to anchored regexes (`^key\s*=\s*value$`) to prevent false positives on comments or stale variables.
- `cmd_security` file-size skips no longer reported as security failures; return code is `0` when only oversized files are skipped.
- `launch-with-mandate.sh` argument filter guarded against `shift 2` crash when `--agent-file` is the final argument without a value.
- `kimi-shell-integration.sh` and `kimi-shell-integration.ps1` env var standardized from `KIMI_CLI_GLOBAL_CONFIG` to `KIMI_GLOBAL_CONFIG` for consistency.
- Dead `CONFIG_SRCS` and `SCRIPT_SRCS` variables removed from root `Makefile`.
- `docs/AGENTS.md` updated with accurate `kimi.toml` line count (~1,492 lines including header).
- `docs/TROUBLESHOOTING.md` added `dos2unix` installation note for Git Bash/MSYS2 users.
- `docs/SECURITY.md` added WSL permission behavior note.
- `make verify` JSON validation fixed: `open('$(DEST)/kimi.json')` changed to `open(r'$(DEST)/kimi.json')` to prevent Python `SyntaxError` on Windows paths containing `\Users` (Unicode escape truncation).
- CI workflow hardened: `test-windows-pwsh` job now explicitly sets `shell: pwsh` on all `run` steps to prevent accidental execution in a different shell interpreter.
- Added PowerShell-native `Check sync` step to `test-windows-pwsh` that mirrors the Unix `make sync` behavior without requiring `cmp`/`diff` (config.toml↔kimi.toml body comparison, mandate-agent.yaml↔mandate-kimiko-agent.yaml equality).
- `docs/CONTRIBUTING.md` added "Platform Notes for Contributors" table documenting which `make` targets work on each platform.

### Added
- `docs/ARCHITECTURE.md` with 8 ADRs documenting cross-platform design decisions (mirror configs, WSL detection, return-code aggregation, four-layer mandate mesh, platform gating, `HOME_FWD`, schema hierarchy, non-blocking compliance).

## [2.0.0] — 2026-04-28

### Added
- Comprehensive zero-blocker mandate configuration (`config.toml`, `kimi.toml`).
- Full malware generation and anti-forensics allow-list (`admin.malwareGeneration*`).
- `entry_protocol` with activation code and capability announcement.
- Validator subproject with JSON Schemas (Draft 2020-12) and pytest suite.

> **Note:** Versions prior to the public repo release were maintained privately.
