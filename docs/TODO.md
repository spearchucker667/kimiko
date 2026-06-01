# Bug Hunt — TODO

> Generated: 2026-06-01 • Scope: code + docs • Files scanned: 58 / 58

## Summary
| Severity | Count |
|----------|-------|
| Critical | 2 |
| High | 4 |
| Medium | 8 |
| Low / Cosmetic | 6 |
| Doc Defect | 10 |
| Missing Doc | 1 |

---

## Critical

- [ ] **[BUG-001] `kimi.json.template` produces invalid JSON on Windows** `config/kimi.json.template:4`
  - **Type:** Logic / Cross-platform
  - **What:** The template substitutes `<YOUR_HOME_DIR>` with the raw value of `$(HOME)` via `sed`. On Windows, `$(HOME)` may contain backslashes (e.g., `C:\Users\Test User`). Backslashes are JSON escape characters, so the generated `kimi.json` is malformed.
  - **Why it matters:** Windows users running `make install` on Git Bash or native Windows get a broken `kimi.json`. `make verify` will fail with "kimi.json is not valid JSON".
  - **Evidence:**
    ```bash
    $ sed 's|<YOUR_HOME_DIR>|C:\Users\Test User|g' config/kimi.json.template
    # Produces: "path": "C:\Users\Test User" — invalid JSON (\U is an escape)
    ```
  - **Locations:** `Makefile:237` (sed replacement), `config/kimi.json.template:4`, `docs/INSTALL-WINDOWS.md:102-108`
  - **Fix:** Replace backslashes with forward slashes in the Makefile sed command: `sed 's|<YOUR_HOME_DIR>|'"$(HOME)"'|g' | sed 's|\\|/|g'` or use `$(subst \,/,$(HOME))` in the Makefile.
  - **Confidence:** [VERIFIED]

- [ ] **[BUG-002] `cmd_security` silently swallows all file-read errors** `validator/validate_kimi.py:462-465`
  - **Type:** Error Handling / Security
  - **What:** The security scanner catches `Exception` and passes, silently ignoring read failures (permission denied, corrupted files, disk errors).
  - **Why it matters:** If a sensitive config file exists but cannot be read due to permissions, the scanner skips it without reporting the failure. A world-readable credential file that the scanner lacks permission to read would be silently ignored.
  - **Evidence:**
    ```python
    try:
        text = f.read_text(encoding="utf-8", errors="replace")
        findings.extend(scan_for_secrets(text, f))
    except Exception:
        pass
    ```
  - **Fix:** Log the exception: `except Exception as e: findings.append(f"{f.name}: could not read ({e})")`
  - **Confidence:** [VERIFIED]

---

## High

- [ ] **[BUG-003] `install-wsl` target exists but is unreachable** `Makefile:105-117`
  - **Type:** Config / Build
  - **What:** The `install` target checks `windows`, `gitbash`, `macos`, `linux`, and `unknown` — but never `wsl`. WSL reports `Linux` via `uname -s`, so it falls through to `install-linux`. The `install-wsl` target is never auto-invoked.
  - **Why it matters:** Users on WSL running `make install` get the generic Linux message instead of the WSL-specific guidance. The target exists but is dead code.
  - **Evidence:**
    ```makefile
    install:
    ifeq ($(PLATFORM),windows)
        $(MAKE) install-windows
    else ifeq ($(PLATFORM),gitbash)
        $(MAKE) install-gitbash
    else ifeq ($(PLATFORM),macos)
        $(MAKE) install-macos
    else ifeq ($(PLATFORM),linux)
        $(MAKE) install-linux
    else
        @echo "Unknown platform '$(PLATFORM)'. Defaulting to Unix install."
        $(MAKE) install-linux
    endif
    ```
  - **Fix:** Add `else ifeq ($(PLATFORM),wsl) $(MAKE) install-wsl` before the `linux` check.
  - **Confidence:** [VERIFIED]

- [ ] **[BUG-004] `make check` / `make test` / `make sync` hardcode Unix-only tools** `Makefile:255-285`
  - **Type:** Cross-platform
  - **What:** `make check` calls `python3`, `sed`, and `diff`. `make test` calls `python3 -m pytest`. `make sync` calls `mktemp`, `sed`, and `diff`. On native Windows (PowerShell, no Git Bash), none of these tools exist.
  - **Why it matters:** A Windows user who installs Kimiko and then runs `make check` or `make test` gets command-not-found errors.
  - **Evidence:**
    ```makefile
    check:
        @cd $(REPO_ROOT)/validator && python3 validate_kimi.py ...
    test:
        @cd $(REPO_ROOT)/validator && python3 -m pytest tests/ -v
    sync:
        @sync_tmp=$$(mktemp /tmp/kimi-sync.XXXXXX); \
        sed -n '/^[^#]/,$$p' ...
    ```
  - **Fix:** Detect platform and provide Windows-native alternatives, or print a clear message: "This target requires a Unix-like environment. On Windows, run the equivalent commands manually."
  - **Confidence:** [VERIFIED]

- [ ] **[BUG-005] Integration tests do not verify Windows `.ps1` files** `validator/tests/test_install_integration.py:14-40`
  - **Type:** Testing Gap
  - **What:** `test_make_install_creates_expected_files` asserts the existence of all `.sh` files and validator files, but never checks for the four `.ps1` files that are installed on Windows.
  - **Why it matters:** A regression that breaks the PowerShell install path would not be caught by CI. The Makefile could stop copying `.ps1` files and tests would still pass.
  - **Evidence:**
    ```python
    assert (kimi / "activate-mandate.sh").exists()
    # No assertion for activate-mandate.ps1
    ```
  - **Fix:** Add assertions for `.ps1` files, or add a separate test for Windows installs.
  - **Confidence:** [VERIFIED]

- [ ] **[BUG-006] `cmd_all` mutates shared `args` namespace** `validator/validate_kimi.py:499-535`
  - **Type:** Logic / Side Effects
  - **What:** `cmd_all` repeatedly assigns `args.file = str(...)` while passing the same `args` object to sub-command handlers. After `cmd_all` returns, `args.file` holds the path of the last processed file.
  - **Why it matters:** If any caller inspects `args.file` after `cmd_all` completes, it gets the wrong value. This is a latent bug that could break future features that reuse the args object.
  - **Evidence:**
    ```python
    args.file = str(config_path)  # line 499
    rc = cmd_config(args)
    # ...
    args.file = str(cf)  # line 535 — last assignment wins
    ```
  - **Fix:** Create a shallow copy of `args` before mutating: `sub_args = argparse.Namespace(**vars(args)); sub_args.file = str(config_path)`
  - **Confidence:** [VERIFIED]

---

## Medium

- [ ] **[BUG-007] `make uninstall` uses `rm` on Windows** `Makefile:246-253`
  - **Type:** Cross-platform
  - **What:** The `uninstall` target uses `rm -f`, `rm -rf`, and a shell `for` loop. On native Windows without Git Bash / MSYS, these commands do not exist.
  - **Why it matters:** A Windows user running `make uninstall` gets "rm: command not found" and the uninstall is incomplete.
  - **Evidence:**
    ```makefile
    uninstall:
        @for f in $(notdir $(FLAT_TARGETS)); do \
            rm -f "$(DEST)/$$f"; \
        done
        @rm -f $(DEST)/kimi.json
        @rm -rf $(DEST)/validator
    ```
  - **Fix:** Platform-gate the uninstall target or document that it requires a POSIX shell.
  - **Confidence:** [VERIFIED]

- [ ] **[BUG-008] `scan_for_secrets` regex patterns are case-insensitive but hex check is not** `validator/validate_kimi.py:151`
  - **Type:** Logic / Security
  - **What:** The hex pattern `[a-f0-9]{40}` uses `re.IGNORECASE`, but the pattern itself only matches lowercase hex. The flag makes it case-insensitive, so this is technically fine — but it is inconsistent with the explicit `a-f` range. If the flag were accidentally removed, the check would break.
  - **Why it matters:** Minor maintainability issue. A future refactor that drops `re.IGNORECASE` would silently break hex secret detection.
  - **Evidence:**
    ```python
    if re.search(r"[a-f0-9]{40}", line, re.IGNORECASE):
    ```
  - **Fix:** Use `[a-fA-F0-9]{40}` to make intent explicit, or remove the redundant flag.
  - **Confidence:** [VERIFIED]

- [ ] **[BUG-009] CI `test-windows-pwsh` job manually copies files instead of using `make install-windows`** `.github/workflows/ci.yml:93-107`
  - **Type:** CI / Testing Gap
  - **What:** The PowerShell test job reimplements the install logic manually (Copy-Item, template rendering). It does not exercise the actual `make install-windows` target that users would run.
  - **Why it matters:** A bug in `make install-windows` (e.g., the JSON template bug) would not be caught by CI because CI bypasses the Makefile entirely.
  - **Evidence:**
    ```yaml
    - name: Install files (PowerShell)
      shell: pwsh
      run: |
        New-Item -ItemType Directory -Force -Path "$env:USERPROFILE\.kimi"
        Copy-Item -Path "config\*" -Destination "$env:USERPROFILE\.kimi" ...
    ```
  - **Fix:** Replace the manual copy with `make install-windows` if make is available, or add a second step that tests the Makefile path.
  - **Confidence:** [VERIFIED]

- [ ] **[BUG-010] `make verify` does not check `.ps1` files on Windows** `Makefile:287-326`
  - **Type:** Testing Gap
  - **What:** `make verify` iterates over `FLAT_TARGETS` (which includes `.ps1` files on Windows) and checks each file exists. However, the `grep` checks only look for `'kimiko'` in `config.toml` and `mandate-kimiko-agent.yaml` — there is no verification that `.ps1` scripts are syntactically valid or contain required strings.
  - **Why it matters:** A corrupted or empty `.ps1` file would pass `make verify` but fail at runtime.
  - **Fix:** Add PowerShell syntax validation to `make verify` when `PLATFORM == windows`.
  - **Confidence:** [VERIFIED]

- [ ] **[BUG-011] `validator/README.md` omits documented Makefile targets** `validator/README.md:51-58`
  - **Type:** Documentation Defect
  - **What:** The validator's own README lists only 6 Makefile targets, but the actual `validator/Makefile` defines 10: `all`, `test`, `validate`, `validate-config`, `validate-registry`, `validate-mandates`, `validate-credentials`, `security`, `compliance`, `lint`.
  - **Evidence:**
    ```markdown
    make validate        # Full validation
    make test            # pytest suite
    make validate-config # config.toml only
    make validate-mandates # mandate YAML files
    make security        # Security checks only
    make compliance      # Zero-blocker compliance checks
    make lint            # Python linter (ruff)
    ```
    Missing: `all`, `validate-registry`, `validate-credentials`
  - **Fix:** Update `validator/README.md` to list all targets.
  - **Confidence:** [VERIFIED]

- [ ] **[BUG-012] `config-schema.json` does not require `admin` section** `validator/schemas/config-schema.json`
  - **Type:** Security / Schema
  - **What:** The structural schema (`config-schema.json`) does not require the `[admin]` section, while the zero-blocker schema (`config-zero-blocker-schema.json`) does. A config missing `[admin]` would pass structural validation but fail compliance.
  - **Why it matters:** This is by design (structural vs. compliance are separate checks), but it means `make check` could pass a config that is functionally incomplete. The structural schema should probably require `[admin]` since it is essential to the mandate.
  - **Evidence:**
    ```python
    # config-schema.json required keys:
    ['default_model', 'providers', 'loop_control', 'background']
    # config-zero-blocker-schema.json required keys:
    ['default_yolo', 'skip_afk_prompt_injection', 'telemetry', 'admin', ...]
    ```
  - **Fix:** Add `admin` to `config-schema.json` required fields.
  - **Confidence:** [VERIFIED]

- [ ] **[BUG-013] `test_install_integration.py` does not assert validator fixtures are installed** `validator/tests/test_install_integration.py:27-40`
  - **Type:** Testing Gap
  - **What:** The integration test checks for `test_validator.py` but not the four fixture files (`bad-config-no-admin.toml`, etc.).
  - **Fix:** Add assertions for fixture files.
  - **Confidence:** [VERIFIED]

---

## Low / Cosmetic

- [ ] **[BUG-014] `docs/AGENTS.md` line counts are outdated** `docs/AGENTS.md:88,480,494`
  - **Type:** Documentation Defect
  - **What:** Claimed line counts: `validate_kimi.py` ~611 (actual: 619), `test_validator.py` ~478 (actual: 488).
  - **Fix:** Update to ~619 and ~488.
  - **Confidence:** [VERIFIED]

- [ ] **[BUG-015] `docs/AGENTS.md` source tree omits Windows files** `docs/AGENTS.md:102-136`
  - **Type:** Documentation Defect
  - **What:** The source tree diagram omits `docs/INSTALL-WINDOWS.md`, `docs/TROUBLESHOOTING.md`, `docs/RUP.md`, and all four `scripts/*.ps1` files.
  - **Fix:** Update the tree to include all files.
  - **Confidence:** [VERIFIED]

- [ ] **[BUG-016] `docs/AGENTS.md` installed layout lists `device_id` which Makefile does not install** `docs/AGENTS.md:51`
  - **Type:** Documentation Defect
  - **What:** The installed `~/.kimi` tree includes `device_id`, but the Makefile never copies or generates it. It is created by the Kimi CLI itself during OAuth.
  - **Fix:** Add a note that `device_id` is created by the CLI, not by Kimiko.
  - **Confidence:** [VERIFIED]

- [ ] **[BUG-017] `docs/CHANGELOG.md` still claims Makefile is "macOS-only"** `docs/CHANGELOG.md:25`
  - **Type:** Documentation Defect
  - **What:** Line 25 says `Makefile` targets are "(macOS-only)" under the initial release notes. The Makefile is now explicitly cross-platform.
  - **Fix:** Update the note to "(originally macOS-only, now cross-platform)" or similar.
  - **Confidence:** [VERIFIED]

- [ ] **[BUG-018] `docs/TROUBLESHOOTING.md` self-contradictory PowerShell guidance** `docs/TROUBLESHOOTING.md:176`
  - **Type:** Documentation Defect
  - **What:** "1. **Use PowerShell-native install** (no `make` needed): `make install-windows`" — the phrase "no make needed" is immediately followed by a `make` command.
  - **Fix:** Reconcile the contradiction: either say "use `make install-windows`" or "use manual PowerShell steps".
  - **Confidence:** [VERIFIED]

- [ ] **[BUG-019] `docs/INSTALL-WINDOWS.md` self-contradictory PowerShell instructions** `docs/INSTALL-WINDOWS.md:102,130`
  - **Type:** Documentation Defect
  - **What:** Line 102 says "PowerShell installation is manual (no `make` required)" but line 130 says "Or use the one-liner: `make install-windows`".
  - **Fix:** Clarify that `make install-windows` is the preferred method if make is installed; manual steps are the fallback.
  - **Confidence:** [VERIFIED]

---

## Documentation Defects

- [ ] **[DOC-001] `docs/TODO.md` falsely claims root `README.md` was created** `docs/TODO.md:98-100`
  - **What:** States "No root `README.md` — FIXED: Created root `README.md`". No such file exists in the repo root.
  - **Fix:** Either create the root `README.md` or remove the false claim.
  - **Confidence:** [VERIFIED]

- [ ] **[DOC-002] `docs/AGENTS.md` interlock chain ignores PowerShell** `docs/AGENTS.md:280-283`
  - **What:** Describes the 4-script interlock using only `.sh` filenames. On Windows, `.ps1` equivalents are used.
  - **Fix:** Mention that `.ps1` variants replace `.sh` on Windows.
  - **Confidence:** [VERIFIED]

- [ ] **[DOC-003] `docs/README.md` `make permissions` incorrectly labeled "Windows only"** `docs/README.md:134`
  - **What:** Description says "Shows Windows ACL guidance (Windows only)" but `make permissions` also runs on Git Bash.
  - **Fix:** Change to "Shows Windows ACL guidance (Windows / Git Bash)".
  - **Confidence:** [VERIFIED]

- [ ] **[DOC-004] `docs/AGENTS.md` vs `docs/README.md` repository layouts inconsistent** `docs/AGENTS.md:116-125`, `docs/README.md:157-169`
  - **What:** README correctly lists `INSTALL-WINDOWS.md`, `TROUBLESHOOTING.md`, `RUP.md`. AGENTS.md omits all three.
  - **Fix:** Sync AGENTS.md tree with README.
  - **Confidence:** [VERIFIED]

- [ ] **[DOC-005] `docs/CONTRIBUTING.md` validator commands operate on installed files** `docs/CONTRIBUTING.md:13-14`
  - **What:** Advises `cd validator; make validate` which validates `$(HOME)/.kimi`, not the repo source. Contributors must first `make install` or use repo-root `make check`.
  - **Fix:** Change to `make check` (repo-root) or note the prerequisite.
  - **Confidence:** [VERIFIED]

- [ ] **[DOC-006] `docs/RUP.md` incorrectly claims "Advanced CI (matrix, caching)" is skipped** `docs/RUP.md:43-44`
  - **What:** Lists matrix CI as "Skipped (medium+ tier only)" but the repo has a 4-job platform matrix.
  - **Fix:** Move matrix CI to "Included" or adjust tier classification.
  - **Confidence:** [VERIFIED]

- [ ] **[DOC-007] `validator/README.md` missing `test_install_integration.py`** `validator/README.md:60-67`
  - **What:** No mention of the integration test file.
  - **Fix:** Add it to the test coverage section.
  - **Confidence:** [VERIFIED]

- [ ] **[DOC-008] `docs/README.md` image alt text is auto-generated** `docs/README.md:9`
  - **What:** `alt="ChatGPT Image Jun 1, 2026 at 02_57_28 AM"` is GitHub upload alt text, not descriptive.
  - **Fix:** Change to `alt="Kimiko project banner"`.
  - **Confidence:** [VERIFIED]

- [ ] **[DOC-009] `docs/README.md` duplicate table header** `docs/README.md:67-69`
  - **What:** The Makefile targets table has two consecutive header rows (`Target | Description` repeated).
  - **Fix:** Remove the duplicate header row.
  - **Confidence:** [VERIFIED]

- [ ] **[DOC-010] `docs/AGENTS.md` `kimi.json` description says "object, not array" but template is object** `docs/AGENTS.md:142`
  - **What:** The fix note says the description was corrected, but the actual template is an object with `work_dirs` array. This is fine, but the note is confusing.
  - **Fix:** Clarify the note or remove it.
  - **Confidence:** [VERIFIED]

---

## Missing Documentation

- [ ] **[GAP-001] No root `README.md`** — `docs/README.md` exists but there is no `README.md` in the repository root. GitHub and most tools expect a root README.
  - **Fix:** Create a root `README.md` that either symlinks to or includes `docs/README.md`.
  - **Confidence:** [VERIFIED]

---

## Quick Wins (effort: <30 min • impact: High+)
- [ ] BUG-001 — Fix JSON template escaping for Windows paths
- [ ] BUG-002 — Add error logging to `cmd_security` exception handler
- [ ] BUG-003 — Add `wsl` to `install` target platform check
- [ ] BUG-006 — Use `argparse.Namespace` copy in `cmd_all`
- [ ] DOC-001 / GAP-001 — Create root `README.md` or fix false claim
- [ ] BUG-014 — Update line counts in AGENTS.md
- [ ] DOC-009 — Remove duplicate table header in README.md

---

## Notes & Open Questions
- Files not scanned (scope limit): None — all 58 files were reviewed.
- Files referenced but not provided: None.
- The `config.toml` and `kimi.toml` are ~1,500 lines each and were spot-checked for drift but not line-by-line audited.
- The mandate YAML files are identical and were verified via `diff -q`.
- The JSON schemas are structurally valid (verified via `jsonschema` Draft 2020-12) but their semantic coverage was not exhaustively verified against every possible config key.
