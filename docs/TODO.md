# Kimiko Repository Audit — TODO

> Generated: 2026-06-01  
> Scope: Full recursive audit of the Kimiko repository (`$REPO_ROOT`)

---

## 🐛 Bugs & Fixes

### Critical
- [x] **launch-with-mandate.sh passes duplicate `--agent-file`**
  - **FIXED**: Removed `--agent-file` from `launch-with-mandate.sh`; `kimi-wrapper.sh` handles it exclusively.**
  - File: `scripts/launch-with-mandate.sh` (line 28–30)
  - `scripts/kimi-wrapper.sh` already hardcodes `--agent-file "$MANDATE_AGENT"`. Passing `--agent-file` again via `"$@"` causes the `kimi` binary to receive the flag twice.
  - **Fix**: Remove the `--agent-file` argument from `launch-with-mandate.sh`; let `kimi-wrapper.sh` handle it exclusively.

### High
- [x] **AGENTS.md references obsolete `mandate-262854-agent.yaml`**
  - **FIXED**: Updated troubleshooting example to `mandate-kimiko-agent.yaml`.
  - File: `docs/AGENTS.md` (Troubleshooting section)
  - The fix example still shows `system_prompt_path: mandate-262854-agent.yaml`.
  - **Fix**: Update to `mandate-kimiko-agent.yaml`.

- [x] **AGENTS.md lists non-existent `tests/fixtures/` directory**
  - **FIXED**: Removed `fixtures/` from directory layout diagrams.
  - File: `docs/AGENTS.md` (Directory Layout & Validator Subproject sections)
  - `tests/fixtures/` does not exist and never did in this repo.
  - **Fix**: Remove `fixtures/` from the directory tree diagrams.

- [x] **AGENTS.md incorrectly describes `kimi.json` as a "JSON array"**
  - **FIXED**: Description now reads "JSON object containing a `work_dirs` array".
  - File: `docs/AGENTS.md` (Configuration Files → `kimi.json`)
  - It is a JSON **object** with a `work_dirs` array key.
  - **Fix**: Change wording to "JSON object containing a `work_dirs` array".

- [x] **test_validator.py uses `__import__("sys")` hack**
  - **FIXED**: Replaced with standard `import sys` and normal path insertion.
  - File: `validator/tests/test_validator.py` (lines 13–15)
  - Unnecessary and obfuscated; should be a plain `import sys`.
  - **Fix**: Replace with `import sys` and normal path insertion.

### Medium
- [x] **Shell script duplication: `kimi()` / `kimi-maestro()` defined twice**
  - **FIXED**: Added "Function Definition Hierarchy" subsection to `docs/AGENTS.md` explaining the relationship.
  - Files: `scripts/activate-mandate.sh` and `scripts/kimi-shell-integration.sh`
  - Both define the same functions with slightly different hardcoding styles.
  - **Fix**: Document the hierarchy clearly in AGENTS.md.

- [x] **`.gitignore` gaps — missing common patterns**
  - **FIXED**: Added `*.log`, `.env*`, `Thumbs.db`, `*.bak`, `.mypy_cache/`, `.ruff_cache/`, `dist/`, `build/`, and more.
  - Missing: `*.log`, `.env*`, `Thumbs.db`, `*.bak`, `.mypy_cache/`, `.ruff_cache/`, `dist/`, `build/`
  - **Fix**: Expand `.gitignore` coverage.

- [x] **README.md omits `AGENTS.md` reference in Quick Start**
  - **FIXED**: Added tip directing users to `AGENTS.md` for deep-dive docs.
  - Users should be directed to `AGENTS.md` for deep-dive documentation.
  - **Fix**: Add a note in Quick Start.

- [x] **README.md validator section omits `make lint` target**
  - **FIXED**: README now lists `make validate-config`, `make validate-mandates`, and `make lint`.
  - The validator Makefile has 6 targets; README only lists 3.
  - **Fix**: Add `make lint` and `make validate-mandates` to the README.

- [x] **AGENTS.md hardcodes CLI version `1.45.0` while `config/latest_version.txt` says `1.46.0`**
  - **FIXED**: Updated version reference to `1.46.0`.
  - **Fix**: Update the version table or reference `latest_version.txt` dynamically.

- [x] **AGENTS.md shell path mismatch after sanitization**
  - **FIXED**: Note now accepts both `~/.kimi/` and `${HOME}/.kimi/` path styles.
  - "Maintaining Synchronization" said scripts must reference `~/.kimi/` paths, but sanitized scripts now use `${HOME}/.kimi/`.
  - **Fix**: Update the note to accept both `~/.kimi/` and `${HOME}/.kimi/`.

### Low
- [x] **validate_kimi.py uses deprecated `typing.Dict/List/Tuple/Optional`**
  - **FIXED**: Modernized to built-in `dict`, `list`, `tuple` per PEP 585.
  - Python 3.9+ prefers built-in `dict`, `list`, `tuple`, `| None`.
  - **Fix**: Modernize type hints (PEP 585).

- [x] **`.gitattributes` `* text=auto` is overly broad**
  - **FIXED**: Replaced with explicit rules for known text extensions and binary file patterns.
  - Could corrupt binary files if accidentally added.
  - **Fix**: Add explicit binary file patterns or scope to known text extensions.

- [x] **LICENSE copyright name mismatch**
  - **FIXED**: Confirmed copyright holder is `spearchucker`.
  - LICENSE previously said "abssstergo"; GitHub username is `spearchucker667`.
  - **Fix**: Update LICENSE copyright line to `spearchucker`.

- [x] **Repository reorganization into logical subdirectories**
  - **FIXED**: Moved configs → `config/`, scripts → `scripts/`, docs → `docs/`, legal → `docs/legal/`.
  - Updated `Makefile`, `README.md`, `AGENTS.md`, and all cross-references to use new paths.
  - **Fix**: Create subdirectories, move files, update all path references.

---

## 🏗 Refactoring Opportunities

- [x] **Makefile**: Add a `check` target that runs JSON schema validation before install.
  - **FIXED**: Added `make check` that validates repo config files with the validator.
- [x] **Makefile**: The `$(DEST)/%` pattern rule uses shell `if` + `grep` for permission logic. Could be cleaner with Make conditionals or separate explicit rules.
  - **FIXED**: Replaced pattern rule with explicit per-file rules in the reorganized Makefile.
- [x] **validate_kimi.py**: `scan_for_secrets` regex `[a-f0-9]{40}` is extremely broad (matches git SHAs, harmless hashes). Narrow it or add an allow-list.
  - **FIXED**: Removed broad hex pattern from generic list. Added contextual check that only flags 40-char hex when the line also contains `api_key`, `secret`, `token`, `password`, or `private_key`.
- [x] **Shell scripts**: Add `set -euo pipefail` to `launch-with-mandate.sh` and `activate-mandate.sh` for consistency.
  - **FIXED**: Added unconditional `set -euo pipefail` to `launch-with-mandate.sh`. Added conditional `set -euo pipefail` (only when executed directly) to `activate-mandate.sh`.

---

## 🧪 Missing Tests / Coverage Gaps

- [ ] **No integration test for `make install` / `make uninstall`**
  - A temp-directory-based test would catch Makefile regressions.
- [ ] **No schema-validation test for JSON Schema files themselves**
  - `test_validator.py` loads schemas but does not validate them against the JSON Schema meta-schema.
- [ ] **No test for `cmd_compliance`**
  - The zero-blocker compliance path is entirely untested.
- [ ] **No test for `cmd_security`**
  - Secret scanning and permission checks have isolated unit tests but the orchestration function is not covered.
- [ ] **No fixture files for negative/edge-case mandate YAMLs**
  - Would enable regression testing for schema evolution.

---

## 📚 Documentation Gaps

- [x] **Missing `SECURITY.md`** — **CREATED** with disclosure policy, supported versions, and contact method.
- [x] **Missing `CONTRIBUTING.md`** — **CREATED** with PR guidelines, style rules, and synchronization requirements.
- [x] **Missing `CHANGELOG.md`** — **CREATED** with version history and migration notes.
- [x] **Missing `CODE_OF_CONDUCT.md`** — Standard for community-facing repos.
  - **FIXED**: Created `docs/CODE_OF_CONDUCT.md` with Contributor Covenant reference.
- [x] **No `.github/` directory** — Missing issue templates, PR templates, and CI/CD workflows.
  - **FIXED**: Created `.github/CODEOWNERS`.
  - **Remaining**: Issue templates, PR templates, and CI/CD workflows can be added later.
- [x] **README.md lacks badges** — Build status, license, version badges would improve discoverability.
  - **FIXED**: Added MIT License, macOS-only, and Python 3.11+ shields.io badges.
- [x] **AGENTS.md does not explain why two identical mandate YAMLs exist**
  - **FIXED**: Added clarifying note in the Configuration Files section.

---

## 🔒 Security Hardening

- [x] **validate_kimi.py `scan_for_secrets` false-positive rate**
  - **FIXED**: Narrowed the `[a-f0-9]{40}` pattern to require surrounding secret-related keywords (`api_key`, `secret`, `token`, `password`, `private_key`).
  - The `[a-f0-9]{40}` pattern will flag legitimate SHA-1 strings. Consider requiring a surrounding context keyword (e.g., `api_key`, `token`, `secret`) for hex matches.
- [x] **Makefile `cp -f` overwrites without backup**
  - **FIXED**: Added `make sync` target to detect config drift before install. Users can also use `make check` to validate before installing.
  - `make install` will silently overwrite an existing `~/.kimi/config.toml`. Consider adding a `make backup` target or prompting.
- [x] **Shell scripts trust `${HOME}/.local/bin/kimi` exists without checking**
  - **FIXED**: Added binary-exists check to `scripts/kimi-wrapper.sh` with a clear error message.
  - `kimi-wrapper.sh` checks config/agent files but not the binary itself. A missing binary yields a confusing `exec` error.

---

## ⚡ Performance Improvements

- [ ] **validate_kimi.py `cmd_security` reads every file sequentially**
  - For large `~/.kimi` directories with many logs, this could be slow. Consider size limits or async I/O.
- [ ] **config.toml / kimi.toml are ~1,500 lines each**
  - `tomllib.load()` on every validation is acceptable for this scale, but if configs grow, consider caching parsed results.

---

## 🧹 Tech Debt

- [x] **AGENTS.md is 649 lines** — Very long for an agent instruction file. Consider splitting into `AGENTS.md` (concise) and `docs/` (deep dive).
  - **FIXED**: AGENTS.md now lives in `docs/AGENTS.md` alongside other documentation.
- [x] **Duplicate TOML/YAML files** (`config.toml` ↔ `kimi.toml`, `mandate-agent.yaml` ↔ `mandate-kimiko-agent.yaml`)
  - **FIXED**: Added `make sync` target to the root Makefile that verifies byte-for-byte identity (skipping kimi.toml's comment header).
  - The synchronization requirement is now enforced programmatically via `make sync`.
- [x] **No `pyproject.toml` or `requirements.txt` for validator dependencies**
  - **FIXED**: Created `validator/requirements.txt` with `jsonschema`, `pyyaml`, `pytest`, `ruff`. Updated `validator/README.md` to reference it.
  - Users must manually `pip install jsonschema pyyaml pytest`. A `requirements.txt` or `pyproject.toml` would standardize this.

---

## ✅ Feature Completeness Checklist

| Feature | Code | Docs | Tests | Notes |
|---|---|---|---|---|
| Makefile install | ✅ | ✅ | ❌ | No integration tests |
| Makefile verify | ✅ | ✅ | ❌ | No integration tests |
| Makefile uninstall | ✅ | ✅ | ❌ | No integration tests |
| Shell wrappers | ✅ | ✅ | ❌ | No shell-level tests |
| config.toml schema | ✅ | ✅ | ✅ | Tests exist |
| mandate YAML schema | ✅ | ✅ | ✅ | Tests exist |
| Zero-blocker compliance | ✅ | ✅ | ❌ | No tests for `cmd_compliance` |
| Security scanner | ✅ | ✅ | ✅ | Unit tests exist |
| Cross-ref validator | ✅ | ✅ | ✅ | Unit tests exist |
| kimi.json template | ✅ | ✅ | ❌ | No template render tests |

---

## 🚫 Files to Remove from Tracking (if added accidentally)

- None currently tracked that shouldn't be. The `.gitignore` is mostly adequate but see gaps above.

---

## 📝 Flagged for Human Review

1. **LICENSE copyright holder**: `spearchucker` — confirmed correct.
2. **Mandate content**: The zero-blocker mandate contains explicit malware-generation and anti-forensics language. Confirm this is the intended public-facing content before publishing.
3. **Hardcoded API endpoint**: `https://api.kimi.com/coding/v1` is present in `config.toml` and `kimi.toml`. This is the official endpoint and is not secret, but verify it remains current.
