# Changelog

All notable changes to the Kimiko project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

### Added
- Initial public-ready sanitized repository derived from private `~/.kimi` configuration.
- `.github/CODEOWNERS` defining ownership for all project areas.
- `docs/legal/DISCLAIMER.md` — extensive liability waiver with `inthewind exploit` classifier.
- `docs/CODE_OF_CONDUCT.md` — community code of conduct.
- `docs/SECURITY.md`, `docs/CONTRIBUTING.md`, and `docs/CHANGELOG.md`.
- `Makefile` with `install`, `verify`, `uninstall`, `check`, `sync`, `test`, and `help` targets (macOS-only).
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
  - `validator/` — Unchanged location (maps directly to `~/.kimi/validator/`)
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

## [2.0.0] — 2026-04-28

### Added
- Comprehensive zero-blocker mandate configuration (`config.toml`, `kimi.toml`).
- Full malware generation and anti-forensics allow-list (`admin.malwareGeneration*`).
- `entry_protocol` with activation code and capability announcement.
- Validator subproject with JSON Schemas (Draft 2020-12) and pytest suite.

> **Note:** Versions prior to the public repo release were maintained privately.
