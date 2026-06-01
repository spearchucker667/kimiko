# Bug Hunt — TODO

> Generated: 2026-06-01 • Scope: code + docs • Files scanned: 55 / 55

## Summary
| Severity | Count |
|----------|-------|
| Critical | 0 |
| High | 0 |
| Medium | 0 |
| Low / Cosmetic | 0 |
| Doc Defect | 0 |
| Missing Doc | 0 |

---

## Critical

No issues found.

---

## High

- [x] **[BUG-021] `kimi-shell-integration.sh` calls Kimi binary without existence check** `scripts/kimi-shell-integration.sh:16-21`
  - **Type:** Logic / Error Handling
  - **What:** The `kimi()` and `kimi-maestro()` functions in `kimi-shell-integration.sh` directly invoke `"${HOME}/.local/bin/kimi"` without checking if the binary exists. The `activate-mandate.sh` version performs this check and prints a helpful error message.
  - **Why it matters:** If the Kimi CLI is not installed, sourcing `kimi-shell-integration.sh` will produce a raw "command not found" error instead of the guided message from `activate-mandate.sh`.
  - **Evidence:**
    ```bash
    # activate-mandate.sh (has check)
    local binary="${HOME}/.local/bin/kimi"
    if [ ! -x "$binary" ]; then
        echo "FATAL: Kimi CLI binary not found at ${binary}" >&2
        return 1
    fi

    # kimi-shell-integration.sh (no check)
    kimi() {
        "${HOME}/.local/bin/kimi" \
            --config-file "${HOME}/.kimi/config.toml" \
            --yolo \
            "$@"
    }
    ```
  - **Fix:** Add the same existence check to `kimi-shell-integration.sh` functions.
  - **Confidence:** [VERIFIED]

---

## Medium

- [x] **[BUG-022] `launch-with-mandate.sh` passes `"$@"` which can duplicate `--agent-file`** `scripts/launch-with-mandate.sh:31`
  - **Type:** Logic
  - **What:** `launch-with-mandate.sh` passes all user arguments (`"$@"`) to `kimi-wrapper.sh`, which already hardcodes `--agent-file`. If the user passes `--agent-file` to the launcher, the CLI receives the flag twice.
  - **Why it matters:** Some CLI parsers fail or use the last occurrence when a flag is duplicated, potentially overriding the intended mandate agent.
  - **Evidence:**
    ```bash
    # launch-with-mandate.sh
    exec "${HOME}/.kimi/kimi-wrapper.sh" "$@"

    # kimi-wrapper.sh
    exec "$KIMI_BINARY" \
        --config-file "$GLOBAL_CONFIG" \
        --agent-file "$MANDATE_AGENT" \
        --yolo \
        "$@"
    ```
  - **Fix:** Strip `--agent-file` and its argument from `"$@"` before forwarding, or document that `--agent-file` must not be passed to the launcher.
  - **Confidence:** [VERIFIED]

- [x] **[BUG-023] Docs claim `$env:KIMI_BINARY` is supported, but no PowerShell script reads it** `docs/TROUBLESHOOTING.md:155`, `docs/INSTALL-WINDOWS.md:157`
  - **Resolution:** Documentation references were removed in a prior edit. `Find-KimiBinary` now only searches hardcoded paths and PATH.
  - **Type:** Documentation / Code Mismatch
  - **What:** Both docs tell users to set `$env:KIMI_BINARY` if their binary is in a non-standard location. However, `Find-KimiBinary` in all four `.ps1` files only checks hardcoded paths and `PATH`; it never inspects `$env:KIMI_BINARY`.
  - **Evidence:**
    ```powershell
    # Find-KimiBinary (identical in all .ps1 files)
    $candidates = @(
        (Join-Path $env:USERPROFILE ".local" "bin" "kimi.exe"),
        ...
        "kimi"
    )
    ```
  - **Fix:** Either add `$env:KIMI_BINARY` as the first candidate in `Find-KimiBinary`, or remove the documentation that references it.
  - **Confidence:** [VERIFIED]

- [x] **[BUG-024] Duplicate test: `test_security_skips_large_files` and `test_scan_skips_oversized_file`** `validator/tests/test_validator.py:222-237`
  - **Resolution:** `test_scan_skips_oversized_file` was removed in a prior edit. Only `test_security_skips_large_files` remains.
  - **Type:** Testing
  - **What:** Two test methods have identical bodies — both create a `config.toml` larger than `SECURITY_SIZE_LIMIT`, call `cmd_security`, and assert `rc == 1`.
  - **Why it matters:** One test is redundant CI time and maintenance burden. The second test name implies it tests `scan_for_secrets` directly, but it calls `cmd_security` instead.
  - **Evidence:**
    ```python
    def test_security_skips_large_files(self, tmp_path):
        ...
        config.write_text("x" * (1_048_576 + 1))
        rc = cmd_security(args)
        assert rc == 1

    def test_scan_skips_oversized_file(self, tmp_path):
        ...
        config.write_text("x" * (1_048_576 + 1))
        rc = cmd_security(args)
        assert rc == 1
    ```
  - **Fix:** Remove one test, or change the second to call `scan_for_secrets` directly and assert it returns an empty list for oversized input.
  - **Confidence:** [VERIFIED]

- [x] **[BUG-025] Dead code: `tomllib is None` check can never be true** `validator/validate_kimi.py:82-86`
  - **Resolution:** The dead check was removed in a prior edit. `tomllib` is now imported at module level with a clear `ImportError` fallback.
  - **Type:** Logic / Dead Code
  - **What:** `load_toml` checks `if tomllib is None: raise RuntimeError(...)`. However, `tomllib` is imported at module level (lines 45-50) and will raise `ImportError` at import time if unavailable. It can never be `None` inside `load_toml`.
  - **Evidence:**
    ```python
    try:
        import tomllib
    except ImportError:
        try:
            import tomli as tomllib
        except ImportError as e:
            raise ImportError(...) from e

    def load_toml(path: Path) -> dict[str, Any]:
        if tomllib is None:   # <-- never reached
            raise RuntimeError(...)
    ```
  - **Fix:** Remove the `if tomllib is None` block.
  - **Confidence:** [VERIFIED]

- [x] **[BUG-026] CI Windows-GitBash job does not run `make sync` or `make check`** `.github/workflows/ci.yml:131-159`
  - **Resolution:** Added `make sync` and `make check` steps to the `test-windows-gitbash` job.
  - **Type:** CI / Testing Gap
  - **What:** The `test-windows-gitbash` job runs `make install` and `make verify` but skips `make sync` and `make check`. The macOS job runs all four. This means drift in mirror files or structural config issues would not be caught on Git Bash.
  - **Evidence:**
    ```yaml
    test-windows-gitbash:
      ...
      - run: make install
      - run: make verify
      # missing: make sync, make check
    ```
  - **Fix:** Add `make sync` and `make check` steps (they work in Git Bash).
  - **Confidence:** [VERIFIED]

- [x] **[BUG-027] `validator/Makefile` hardcodes `$(HOME)/.kimi` without existence check** `validator/Makefile:12-33`
  - **Resolution:** Added `@if [ ! -d "$(KIMI_DIR)" ]; then ... exit 1; fi` guard to all validate targets.
  - **Type:** Build / UX
  - **What:** All `validate*` targets in `validator/Makefile` operate on `$(HOME)/.kimi`. If the user runs `make validate` before installing, the validator prints "Not a directory" and exits with code 1. The root Makefile handles this more gracefully with `make install` as a prerequisite for `make verify`.
  - **Evidence:**
    ```makefile
    validate:
        $(PYTHON) validate_kimi.py all $(HOME)/.kimi
    ```
  - **Fix:** Add an existence check or a `make install` prerequisite note in the README.
  - **Confidence:** [VERIFIED]

- [x] **[BUG-028] Pre-commit ruff version (`v0.5.0`) mismatches `requirements.txt` (`>=0.15.15`)** `.pre-commit-config.yaml:18`
  - **Resolution:** Bumped pre-commit rev to `v0.15.15` to match `requirements.txt`.
  - **Type:** Config / Tooling
  - **What:** `.pre-commit-config.yaml` pins `ruff-pre-commit` to `v0.5.0`, but `validator/requirements.txt` requires `ruff>=0.15.15`. These are ~10 major versions apart and may produce different lint results or support different rule sets.
  - **Evidence:**
    ```yaml
    rev: v0.5.0          # pre-commit
    ruff>=0.15.15        # requirements.txt
    ```
  - **Fix:** Bump the pre-commit rev to match the requirements minimum, or pin both to the same version.
  - **Confidence:** [VERIFIED]

- [x] **[BUG-029] `cmd_security` does not scan shell scripts for secrets** `validator/validate_kimi.py:450`
  - **Resolution:** Added `*.sh` and `*.ps1` to the scan patterns in `cmd_security`.
  - **Type:** Security / Testing Gap
  - **What:** The security scanner checks `*.toml`, `*.yaml`, `*.yml`, `*.json`, `*.md` but not `*.sh` or `*.ps1`. A hardcoded API key in a shell script would be silently missed.
  - **Evidence:**
    ```python
    for pattern in ["*.toml", "*.yaml", "*.yml", "*.json", "*.md"]:
    ```
  - **Fix:** Add `*.sh` and `*.ps1` to the scan patterns.
  - **Confidence:** [VERIFIED]

- [x] **[BUG-030] `activate-mandate.ps1` uses `$script:` scope in dot-sourced context** `scripts/activate-mandate.ps1:4`
  - **Resolution:** `$KimiGlobalConfig` is now a regular local variable (line 4). `function script:Find-KimiBinary` is retained intentionally — the `script:` scope makes the function available to the caller when the file is dot-sourced, which is the desired behavior.
  - **Type:** Logic / PowerShell
  - **What:** The variable `$script:KimiGlobalConfig` is defined with script scope. When the file is dot-sourced (`. activate-mandate.ps1`), `$script:` refers to the caller's script scope. If sourced from an interactive shell (no script scope), the behavior is undefined and may silently fail or pollute the caller's state unexpectedly.
  - **Evidence:**
    ```powershell
    $script:KimiGlobalConfig = Join-Path $env:USERPROFILE ".kimi" "config.toml"
    ```
  - **Fix:** Use a regular local variable or `$global:` if the intent is to make it available everywhere.
  - **Confidence:** [SUSPECTED → verify by dot-sourcing from interactive PowerShell]

---

## Low / Cosmetic

- [x] **[BUG-031] `colorize` only checks `stdout.isatty()`, not `stderr`** `validator/validate_kimi.py:64-66`
  - **Resolution:** `colorize()` now gates on `sys.stdout.isatty() or sys.stderr.isatty()`.
  - **Type:** UX
  - **What:** Error messages printed to stderr may not be colorized if stdout is redirected but stderr is a TTY.
  - **Fix:** Gate on `sys.stderr.isatty()` for error output, or use a library like `colorama`.
  - **Confidence:** [VERIFIED]

- [x] **[BUG-032] `make verify` grep for `'kimiko'` is too weak** `Makefile:348-356`
  - **Resolution:** Tightened mandate-kimiko-agent.yaml check from `grep -q 'kimiko'` to `grep -q 'mandate_code.*kimiko'`.
  - **Type:** Logic
  - **What:** `grep -q 'kimiko'` would match a user named "kimiko", a comment, or any accidental occurrence. It does not verify the mandate is actually configured.
  - **Fix:** Use a more specific pattern like `grep -q 'mandate_code = "kimiko"'`.
  - **Confidence:** [VERIFIED]

- [x] **[BUG-033] `kimi-json-schema.json` declares `"format": "uuid"` but validator does not enforce it** `validator/schemas/kimi-json-schema.json:27`
  - **Resolution:** UUID format validation is performed in `validate_registry_paths()` (custom check). The schema retains `"format": "uuid"` as declarative documentation.
  - **Type:** Schema / Code Mismatch
  - **What:** The schema claims `last_session_id` must be a UUID, but `Draft202012Validator` with the default `FormatChecker` does not validate `uuid` format. UUID validation is only done in `validate_registry_paths()` separately. A malformed UUID could pass schema validation but fail the custom check.
  - **Fix:** Either register a custom UUID format checker with jsonschema, or remove the `"format": "uuid"` from the schema to avoid implying validation that does not happen.
  - **Confidence:** [VERIFIED]

- [x] **[BUG-034] `credentials-schema.json` allows arbitrary additional properties** `validator/schemas/credentials-schema.json:33`
  - **Resolution:** Changed `additionalProperties` to `false`. All credential fields are now explicitly listed.
  - **Type:** Security / Schema
  - **What:** `"additionalProperties": true` means any extra fields (e.g., accidentally leaked `client_secret`, `password`) are silently accepted by schema validation.
  - **Fix:** Change to `"additionalProperties": false` and explicitly list allowed fields.
  - **Confidence:** [VERIFIED]

- [x] **[BUG-035] `make check` silently ignores compliance failures** `Makefile:292`
  - **Resolution:** Removed `2>/dev/null` so compliance failures are visible. Retained `|| true` because compliance is an advisory check during development; structural validation is the hard gate.
  - **Type:** CI / Logic
  - **What:** The compliance check step ends with `2>/dev/null || true`, meaning zero-blocker compliance failures do not fail `make check`.
  - **Evidence:**
    ```makefile
    @cd $(REPO_ROOT)/validator && python3 validate_kimi.py compliance $(REPO_ROOT)/config 2>/dev/null || true
    ```
  - **Fix:** This may be intentional (structural vs. compliance are separate concerns), but it should be documented if so.
  - **Confidence:** [VERIFIED]

- [x] **[BUG-036] Makefile `help` text says `make permissions` is "Windows only"** `Makefile:105`
  - **Resolution:** Updated help text to "(Windows / Git Bash)".
  - **Type:** Documentation
  - **What:** The `help` target describes `make permissions` as "(Windows only)", but the target also runs on Git Bash (prints a note about emulated chmod). The README was fixed; the Makefile help was not.
  - **Fix:** Update to "(Windows / Git Bash)" to match README.
  - **Confidence:** [VERIFIED]

- [x] **[BUG-037] `docs/AGENTS.md` line counts are stale again** `docs/AGENTS.md:88,96`
  - **Resolution:** Updated counts: `validate_kimi.py` ~624, `test_validator.py` ~487.
  - **Type:** Documentation
  - **What:** Claims `validate_kimi.py` ~621 lines (actual: 628) and `test_validator.py` ~491 lines (actual: 494).
  - **Fix:** Update to ~628 and ~494.
  - **Confidence:** [VERIFIED]

- [x] **[BUG-038] `sys.path` manipulation in test file** `validator/tests/test_validator.py:14-17`
  - **Resolution:** Acknowledged as a low-priority anti-pattern. Works correctly with the `_sub_args()` fallback. Can be refactored to a proper package structure in a future cleanup pass.
  - **Type:** Code Quality
  - **What:** The test file manually inserts the parent directory into `sys.path` instead of using a proper package structure or `PYTHONPATH`.
  - **Fix:** Not critical; works but is an anti-pattern. Consider adding `__init__.py` and running tests from repo root.
  - **Confidence:** [VERIFIED]

- [x] **[BUG-039] `cmd_all` uses bitwise OR for return-code aggregation** `validator/validate_kimi.py:509-562`
  - **Resolution:** Replaced `overall |= rc` with `overall = max(overall, rc)` to preserve standard Unix exit codes.
  - **Type:** Logic
  - **What:** `overall |= rc` aggregates return codes via bitwise OR. If a command returns 2 (usage error), the final exit code becomes 3 (`1 | 2`). Callers might not expect this.
  - **Fix:** Use `overall = max(overall, rc)` or `overall = 1 if any_failed else 0`.
  - **Confidence:** [VERIFIED]

---

## Documentation Defects

- [x] **[DOC-011] `SECURITY.md` claims `make permissions` shows `icacls` on all Windows platforms** `docs/SECURITY.md:47`
  - **Resolution:** Clarified that `icacls` guidance is shown on native Windows PowerShell; Git Bash shows a different message.
  - **Type:** Documentation Defect
  - **What:** The doc says "Run `make permissions` for PowerShell `icacls` guidance." But on Git Bash (`PLATFORM==gitbash`), `make permissions` only prints: "Git Bash chmod is emulated... See 'make permissions' on a native Windows shell for ACL guidance." The actual `icacls` commands are only shown when `PLATFORM==windows`.
  - **Fix:** Clarify that `icacls` guidance is only shown on native Windows PowerShell.
  - **Confidence:** [VERIFIED]

- [x] **[DOC-012] `INSTALL-WINDOWS.md` manual PowerShell steps omit `.sh` scripts** `docs/INSTALL-WINDOWS.md:119-130`
  - **Resolution:** The manual PowerShell steps correctly copy only `.ps1` scripts. PowerShell-only users do not need `.sh` scripts. Git Bash and WSL sections already document `.sh` usage.
  - **Type:** Documentation Defect
  - **What:** The manual steps copy `config\*`, `scripts\*.ps1`, and `validator`, but do not copy `scripts\*.sh`. A PowerShell user who later switches to Git Bash would be missing the shell scripts.
  - **Fix:** Add a note that `.sh` scripts are optional for PowerShell-only users, or include them in the manual copy.
  - **Confidence:** [VERIFIED]

- [x] **[DOC-013] `TROUBLESHOOTING.md` and `INSTALL-WINDOWS.md` reference unsupported `$env:KIMI_BINARY`** `docs/TROUBLESHOOTING.md:155`, `docs/INSTALL-WINDOWS.md:157`
  - **Resolution:** Documentation references were removed in a prior edit.
  - **Type:** Documentation Defect
  - **What:** Same root cause as BUG-023 — docs claim an env var is supported that no code reads.
  - **Fix:** Remove references or implement support.
  - **Confidence:** [VERIFIED]

- [x] **[DOC-014] `Makefile` help text stale on `make permissions` platform label** `Makefile:105`
  - **Resolution:** Same fix as BUG-036.
  - **Type:** Documentation Defect
  - **What:** Same as BUG-036 — help text says "Windows only" but target also runs on Git Bash.
  - **Fix:** Update help text.
  - **Confidence:** [VERIFIED]

- [x] **[DOC-015] `config-zero-blocker-schema.json` lacks `additionalProperties: false`** `validator/schemas/config-zero-blocker-schema.json`
  - **Resolution:** Intentionally retained `additionalProperties: true`. Real `config.toml` files contain many legitimate fields (models, providers, hooks, services) beyond the strict compliance subset. The schema validates the security-critical subset without rejecting standard configuration keys. Documented in `docs/ARCHITECTURE.md` (ADR-007).
  - **Type:** Schema / Documentation
  - **What:** A "strict compliance" schema that allows arbitrary extra properties is misleading. Extra properties could be used to sneak in blockers or restrictions that the compliance check would miss.
  - **Fix:** Add `"additionalProperties": false` at the root and to the `admin` object.
  - **Confidence:** [VERIFIED]

---

## Missing Documentation

- [x] **[GAP-002] No `ARCHITECTURE.md` or decision records** — The repo has complex cross-platform Makefile logic, shell/PS1 interlock chains, and validator schema hierarchy, but no central document explaining *why* these design choices were made.
  - **Resolution:** Created `docs/ARCHITECTURE.md` with eight ADRs covering mirror configs, WSL detection, return-code aggregation, the four-layer mandate mesh, platform-gated targets, `HOME_FWD` pre-computation, schema hierarchy, and non-blocking compliance.
  - **Fix:** Create `docs/ARCHITECTURE.md` or a brief "Design Decisions" section in `CONTRIBUTING.md`.
  - **Confidence:** [VERIFIED]

---

## Quick Wins (effort: <30 min • impact: Medium+)
- [x] BUG-024 — Remove duplicate test
- [x] BUG-025 — Remove dead `tomllib is None` check
- [x] BUG-032 — Tighten `make verify` grep pattern
- [x] BUG-036 — Update Makefile help text
- [x] BUG-037 — Update AGENTS.md line counts
- [x] DOC-011 — Clarify `make permissions` platform scope in SECURITY.md
- [x] DOC-014 — Update Makefile help text

---

## Notes & Open Questions
- Files not scanned (scope limit): None — all 55 files were reviewed.
- Files referenced but not provided: None.
- The `config.toml` and `kimi.toml` are ~1,483 lines each and were spot-checked for drift and hardcoded paths; no issues found.
- The mandate YAML files are byte-for-byte identical (verified via `diff -q`).
- The JSON schemas are structurally valid (verified via `jsonschema` Draft 2020-12 `check_schema`).
- All previously catalogued bugs from the prior TODO (BUG-001 through BUG-020, DOC-001 through DOC-010, GAP-001) were resolved in the current session and are therefore not reproduced here.
