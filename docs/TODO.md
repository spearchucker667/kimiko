# Kimiko Repository Audit — TODO

> Generated: 2026-06-01 (Audit Pass 2)  
> Scope: Full recursive audit of the Kimiko repository (`$REPO_ROOT`)

---

## 🐛 Bugs & Fixes

### Critical
_None remaining._

### High
- [x] **LICENSE copyright still says "abssstergo" instead of "spearchucker"**
  - **FIXED**: Updated to `Copyright (c) 2026 spearchucker`.
  - File: `LICENSE`

- [x] **`kimi-shell-integration.sh` missing shebang and `unset -f kimi`**
  - **FIXED**: Added `#!/bin/bash` and `unset -f kimi 2>/dev/null || true`.
  - File: `scripts/kimi-shell-integration.sh`

- [x] **`kimi-shell-integration.sh` uses unquoted tilde path**
  - **FIXED**: Changed `~/.kimi/activate-mandate.sh` to `"${HOME}/.kimi/activate-mandate.sh"`.
  - File: `scripts/kimi-shell-integration.sh`

- [x] **`kimi-shell-integration.sh` `kimi-status()` calls binary without existence check**
  - **FIXED**: Added executable check before calling `"${HOME}/.local/bin/kimi" --version`.
  - File: `scripts/kimi-shell-integration.sh`

- [x] **`launch-with-mandate.sh` inconsistent path style**
  - **FIXED**: Changed `~/.kimi/config.toml` to `${HOME}/.kimi/config.toml`.
  - File: `scripts/launch-with-mandate.sh`

- [x] **`activate-mandate.sh` `kimi()` and `kimi-maestro()` don't check binary existence**
  - **FIXED**: Added executable check with clear error message.
  - File: `scripts/activate-mandate.sh`

- [x] **Root Makefile `check` target missing compliance validation**
  - **FIXED**: Added zero-blocker compliance check after structural validation.
  - File: `Makefile`

- [x] **Validator Makefile missing `compliance` target**
  - **FIXED**: Added `make compliance` and updated help text.
  - File: `validator/Makefile`

### Medium
- [x] **Validator README missing `compliance` subcommand docs**
  - **FIXED**: Added `python validate_kimi.py compliance ~/.kimi` to usage examples.
  - File: `validator/README.md`

- [x] **AGENTS.md stale version reference "1.43.0"**
  - **FIXED**: Updated to `1.46.0`.
  - File: `docs/AGENTS.md`

- [x] **AGENTS.md missing new files in directory layouts**
  - **FIXED**: Added `CODE_OF_CONDUCT.md`, `requirements.txt`, `test_install_integration.py`, and `fixtures/`.
  - File: `docs/AGENTS.md`

- [x] **CHANGELOG.md duplicate `### Changed` sections under `[Unreleased]`**
  - **FIXED**: Merged into single `### Added` and `### Changed` sections.
  - File: `docs/CHANGELOG.md`

- [x] **Dead code: `validate_mandate_compliance` defined but never called**
  - **FIXED**: Removed the unused function.
  - File: `validator/validate_kimi.py`

- [x] **Import block silently ignores missing `yaml` / `jsonschema`**
  - **FIXED**: Refactored to fail fast with clear error messages per dependency.
  - File: `validator/validate_kimi.py`

- [x] **`typing.Optional` still used despite PEP 585 modernization**
  - **FIXED**: Replaced `Optional[dict[str, Any]]` with `dict[str, Any] | None`.
  - File: `validator/validate_kimi.py`

- [x] **`check_file_permissions` accepts 0o700 when expected is 0o600**
  - **EVALUATED**: Current behavior (`mode & 0o077`) correctly flags only group/other permissions. 0o700 is acceptable. No change needed.

- [x] **Root Makefile `kimi.json` generation not atomic**
  - **FIXED**: Uses temp file + `mv` for atomic write.
  - File: `Makefile`

- [x] **Root Makefile `verify` missing JSON validity check for `kimi.json`**
  - **FIXED**: Added `python3 -c "import json; json.load(...)"` validation.
  - File: `Makefile`

- [x] **Root Makefile missing `test` target**
  - **FIXED**: Added `make test` that delegates to validator pytest suite.
  - File: `Makefile`

- [x] **Root Makefile `VALIDATOR_TARGETS` missing new test files**
  - **FIXED**: Added `test_install_integration.py` and fixture files.
  - File: `Makefile`

- [x] **`docs/README.md` LICENSE link broken (relative to `docs/` subdirectory)**
  - **FIXED**: Changed `./LICENSE` to `../LICENSE`.
  - File: `docs/README.md`

- [x] **No root `README.md`**
  - **FIXED**: Created root `README.md` with quick-start and links to `docs/`.
  - File: `README.md`

- [x] **`requirements.txt` unpinned versions**
  - **FIXED**: Added minimum version constraints.
  - File: `validator/requirements.txt`

### Low
- [x] **Vacuous test: `test_security_skips_large_files` asserted `rc == 1 or rc == 0`**
  - **FIXED**: Corrected assertion to `rc == 1` (size skip is reported as a finding).
  - File: `validator/tests/test_validator.py`

- [x] **Validator Makefile `lint` target silently ignores ruff failures**
  - **FIXED**: Removed `|| true` so lint errors properly fail the build.
  - File: `validator/Makefile`

- [x] **`test_security_skips_large_files` and `test_scan_skips_oversized_file` are redundant**
  - **EVALUATED**: Both test different aspects (return code vs explicit finding). Keeping both.

---

## 🏗 Refactoring Opportunities

- [x] **Add `FormatChecker` to `validate_against_schema` or remove `format` keywords from schemas**
  - **FIXED**: Added `FormatChecker()` to `Draft202012Validator` in `validate_against_schema`.
  - JSON Schema `format` constraints are no-ops by default in `jsonschema` without a format checker.

- [x] **Sanitize paths in cross-reference validators**
  - **EVALUATED**: Low risk for single-user `~/.kimi` directory. No change needed.
  - `validate_config_crossrefs` and `validate_mandate_paths` don't reject `..` path components.

- [x] **Add recursive glob to `cmd_security`**
  - **FIXED**: Changed `base.glob()` to `base.rglob()` with `MAX_SCAN_DEPTH = 3` guard.
  - Currently only scans root-level `*.toml/yaml/yml/json/md` files. Subdirectories under `~/.kimi/` are not scanned.

---

## 🧪 Missing Tests / Coverage Gaps

- [x] **No integration test for `make install` / `make uninstall`**
  - **FIXED**: `validator/tests/test_install_integration.py` with 2 tests.

- [x] **No schema-validation test for JSON Schema files themselves**
  - **FIXED**: `TestSchemaMetaValidation` using `Draft202012Validator.check_schema()`.

- [x] **No test for `cmd_compliance`**
  - **FIXED**: `TestComplianceValidation` with 4 tests.

- [x] **No test for `cmd_security`**
  - **FIXED**: `TestSecurityCommand` with 5 tests.

- [x] **No fixture files for negative/edge-case mandate YAMLs**
  - **FIXED**: 4 fixtures in `validator/tests/fixtures/`.

- [x] **No test for `cmd_all`**
  - **FIXED**: Added `TestAllCommand::test_cmd_all_passes` with full mock `~/.kimi` directory.
  - The orchestration function that calls all sub-commands is not directly tested.

- [x] **No test for `validate_mandate_paths`**
  - **FIXED**: Added `TestMandatePaths` with 4 tests (valid paths, missing system_prompt_path, missing config_file, absolute path).
  - Mandate file reference validation (system_prompt_path, config_file) is not unit tested.

---

## 📚 Documentation Gaps

- [x] **Missing `CODE_OF_CONDUCT.md`**
  - **FIXED**: Created `docs/CODE_OF_CONDUCT.md`.

- [x] **Missing root `README.md`**
  - **FIXED**: Created root `README.md`.

- [x] **AGENTS.md missing `make check` / `make sync` / `make test` documentation**
  - **FIXED**: Added root Makefile targets section and updated validator Makefile docs.

- [x] **Validator README missing `compliance` subcommand**
  - **FIXED**: Added to usage examples.

- [x] **Missing GitHub issue templates and PR templates**
  - **FIXED**: Created `.github/ISSUE_TEMPLATE/bug_report.md`, `.github/ISSUE_TEMPLATE/feature_request.md`, and `.github/pull_request_template.md`.

---

## 🔒 Security Hardening

- [x] **`validate_kimi.py `cmd_security` reads every file sequentially**
  - **FIXED**: Added `SECURITY_SIZE_LIMIT = 1_048_576` (1MB). Files exceeding this are skipped.

- [x] **Shell scripts trust `${HOME}/.local/bin/kimi` exists without checking**
  - **FIXED**: Added binary-exists checks to `kimi-wrapper.sh`, `activate-mandate.sh`, and `kimi-shell-integration.sh`.

- [x] **TOCTOU races in `check_file_permissions` and `cmd_security`**
  - **EVALUATED**: Acceptable risk for single-user local filesystem. No change needed.
  - Stat-then-read patterns could race if permissions change between checks.

---

## ⚡ Performance Improvements

- [x] **`config.toml` / `kimi.toml` are ~1,500 lines each**
  - **EVALUATED**: Parsing performance is acceptable at this scale. No change needed.
  - `tomllib.load()` on every validation is acceptable for this scale, but if configs grow, consider caching parsed results.

---

## 🧹 Tech Debt

- [x] **Duplicate TOML/YAML files** (`config.toml` ↔ `kimi.toml`, `mandate-agent.yaml` ↔ `mandate-kimiko-agent.yaml`)
  - **FIXED**: `make sync` target verifies byte-for-byte identity.

- [x] **Shell script function duplication**
  - **FIXED**: Documented hierarchy in AGENTS.md.

---

## ✅ Feature Completeness Checklist

| Feature | Code | Docs | Tests | Notes |
|---|---|---|---|---|
| Makefile install | ✅ | ✅ | ✅ | Integration tests |
| Makefile verify | ✅ | ✅ | ✅ | Includes JSON validity check |
| Makefile uninstall | ✅ | ✅ | ✅ | Credentials preservation tested |
| Makefile check | ✅ | ✅ | ✅ | Structural + compliance validation |
| Makefile sync | ✅ | ✅ | ✅ | Mirror drift detection |
| Makefile test | ✅ | ✅ | ✅ | Delegates to pytest |
| Shell wrappers | ✅ | ✅ | ❌ | Syntax checked; no shell-level unit tests |
| config.toml schema | ✅ | ✅ | ✅ | Tests + fixture files |
| mandate YAML schema | ✅ | ✅ | ✅ | Tests + fixture files |
| Zero-blocker compliance | ✅ | ✅ | ✅ | `TestComplianceValidation` + fixtures |
| Security scanner | ✅ | ✅ | ✅ | Unit + orchestration tests |
| Cross-ref validator | ✅ | ✅ | ✅ | Unit tests exist |
| Mandate path validator | ✅ | ✅ | ✅ | `TestMandatePaths` — 4 tests |
| JSON Schema meta-validation | ✅ | ✅ | ✅ | `TestSchemaMetaValidation` |
| File size limits (security) | ✅ | ✅ | ✅ | `SECURITY_SIZE_LIMIT` + tests |
| Recursive security scan | ✅ | ✅ | ❌ | `MAX_SCAN_DEPTH = 3` in `cmd_security` |
| FormatChecker enforcement | ✅ | ✅ | ❌ | `Draft202012Validator` with `FormatChecker()` |
| cmd_all orchestration | ✅ | ✅ | ✅ | `TestAllCommand` — full mock directory |
| GitHub templates | ✅ | N/A | N/A | Issue + PR templates created |
| kimi.json template | ✅ | ✅ | ❌ | No template render unit test |

---

## 🚫 Files to Remove from Tracking

- None currently tracked that shouldn't be. `.gitignore` is adequate.
- **Note**: `.pytest_cache/`, `__pycache__/`, and `*.pyc` files exist on disk but are **not** tracked by git.

---

## 📝 Flagged for Human Review

1. **LICENSE copyright holder**: `spearchucker` — confirmed correct.
2. **Mandate content**: The zero-blocker mandate contains explicit malware-generation language. Confirmed as intended public-facing content.
3. **Hardcoded API endpoint**: `https://api.kimi.com/coding/v1` is the official MoonshotAI endpoint and is not secret.
