# Architecture Decision Records (ADRs)

This document captures the key design decisions in the Kimiko repository and the reasoning behind them.

---

## ADR-001: Mirror Config Files (`config.toml` ↔ `kimi.toml`)

**Status:** Accepted
**Context:** The live configuration is `config.toml`. If it is corrupted or overwritten by an update, the mandate could be silently deactivated.

**Decision:** Maintain a byte-for-byte hardened mirror (`kimi.toml`) that is identical to `config.toml` except for an optional comment header. A `make sync` target verifies they remain synchronized.

**Consequences:**
- (+) Mandate persistence even if the primary config is damaged.
- (-) Every edit to `config.toml` must be mirrored to `kimi.toml`.
- (-) Slightly larger install footprint.

---

## ADR-002: WSL Detection via `uname -r`

**Status:** Accepted
**Context:** WSL shares the Linux kernel interface but runs on top of Windows. We need to distinguish native Linux from WSL because:
- WSL users may have `$HOME` pointing to `/mnt/c/...` (NTFS) where `chmod` is a no-op.
- WSL users should be warned to install in the native ext4 filesystem (`/home/...`).

**Decision:** Detect WSL by grepping `uname -r` for `microsoft` or `WSL`. This is the standard, most reliable heuristic (Microsoft's WSL kernel includes these strings in the release identifier).

**Consequences:**
- (+) Single-line shell check, no external dependencies.
- (-) If Microsoft changes the kernel release string, detection could break. This is considered low-risk because the string has been stable since WSL1.

---

## ADR-003: Makefile `cmd_all` Return-Code Aggregation via `max()`

**Status:** Accepted
**Context:** `cmd_all` runs multiple sub-validators (config, registry, mandate, credentials, security) and must return a single exit code.

**Decision:** Aggregate with `overall = max(overall, rc)` instead of bitwise OR (`overall |= rc`).

**Rationale:**
- Bitwise OR (`1 | 2 = 3`) produces non-standard exit codes that can confuse CI systems and shell scripts.
- `max()` preserves standard Unix semantics: `0` = success, `1` = failure.

**Consequences:**
- (+) Predictable exit codes for CI and wrapper scripts.
- (-) Loses the ability to distinguish *which* sub-command failed from the exit code alone (the summary table already prints this).

---

## ADR-004: Four-Layer Mandate Enforcement Mesh

**Status:** Accepted
**Context:** Mandate kimiko requires absolute, irreversible enforcement. A single point of failure is unacceptable.

**Decision:** Implement four interlocking layers:

1. **Primary Runtime Config** (`config.toml`) — Live configuration loaded on every CLI startup.
2. **Mirror Config** (`kimi.toml`) — Synchronized backup that serves as a fallback.
3. **Mandate Agent Specs** (`mandate-agent.yaml`, `mandate-kimiko-agent.yaml`) — YAML agent specifications that reference `system-prompts/kimiko.md` via `system_prompt_path`, loading the mandate system prompt into every session.
4. **Shell Integration** (`*.sh`, `*.ps1`) — Enforces mandate at the OS shell level before the CLI even starts.

Each layer cross-references the others. No single file operates in isolation.

**Consequences:**
- (+) Structural impossibility of accidental deactivation.
- (-) Higher maintenance burden; all four layers must be kept in sync.

---

## ADR-005: Platform-Gated Makefile Targets

**Status:** Accepted
**Context:** Kimiko supports macOS, Linux, WSL, Git Bash (MINGW/MSYS), and native PowerShell. Not all targets make sense on all platforms.

**Decision:** Use `PLATFORM` auto-detection at Makefile parse time and gate targets (`check`, `sync`, `test`, `uninstall`) with clear error messages when invoked on an incompatible platform.

**Platform Matrix:**

| Target | macOS | Linux | WSL | Git Bash | PowerShell |
|---|---|---|---|---|---|
| `install` | ✓ | ✓ | ✓ | ✓ | ✓ (via `install-windows`) |
| `check` | ✓ | ✓ | ✓ | ✓ | ✗ (error) |
| `sync` | ✓ | ✓ | ✓ | ✓ | ✗ (error) |
| `test` | ✓ | ✓ | ✓ | ✓ | ✗ (error) |
| `uninstall` | ✓ | ✓ | ✓ | ✓ | ✗ (shows PS command) |
| `verify` | ✓ | ✓ | ✓ | ✓ | ✓ |
| `permissions` | message | message | message | message | icacls guidance |

**Consequences:**
- (+) Users get immediate, actionable feedback instead of cryptic failures.
- (-) PowerShell users must run validator tests via `cd validator; pytest` directly.

---

## ADR-006: `HOME_FWD` Pre-Computation for Template Substitution

**Status:** Accepted
**Context:** On native Windows PowerShell, the `HOME` environment variable is frequently undefined. The `kimi.json` template requires a home-directory path substitution.

**Decision:** Compute `HOME_FWD` once at Makefile parse time: use `USERPROFILE` (with backslash-to-slash substitution) on Windows, otherwise `HOME`.

**Consequences:**
- (+) Eliminates empty-path bugs in `kimi.json` when `HOME` is unset.
- (+) Centralizes path logic in one variable.
- (-) `USERPROFILE` on Windows may contain spaces, but the `subst` function handles them correctly in Make.

---

## ADR-007: Validator Schema Hierarchy

**Status:** Accepted
**Context:** We need both structural validation ("is this well-formed?") and compliance validation ("does this adhere to Mandate kimiko?").

**Decision:** Maintain two schema files per config type:

| File | Purpose | `additionalProperties` |
|---|---|---|
| `config-schema.json` | Structural validation | `true` (allows extra keys) |
| `config-zero-blocker-schema.json` | Mandate compliance | `true` (allows extra keys; only validates critical subset) |
| `mandate-schema.json` | Structural validation | `false` |
| `mandate-zero-blocker-schema.json` | Mandate compliance | `false` |

**Rationale:** Real `config.toml` files contain many legitimate fields beyond the strict compliance subset (models, providers, hooks, services, etc.). Rejecting them would make the compliance check unusable on real configs.

**Consequences:**
- (+) Compliance checks work against production configs without false positives.
- (-) A malicious config could pass compliance while containing unexpected keys. This is acceptable because the compliance schema validates the *security-critical* subset.

---

## ADR-008: Non-Blocking Compliance in `make check`

**Status:** Accepted
**Context:** `make check` runs structural validation followed by zero-blocker compliance validation against the source `config/` directory.

**Decision:** The compliance step uses `|| true` so that `make check` does not fail on compliance violations.

**Rationale:**
- Source configs in `config/` may be partially compliant during development.
- Structural validation (`config-schema.json`) is the hard gate; compliance is an advisory check.
- CI runs the compliance check explicitly in a separate step.

**Consequences:**
- (+) `make check` remains usable during active development.
- (-) Developers must pay attention to the compliance output; failures are visible but non-fatal.

---

## ADR-009: External System Prompt File (`system-prompts/kimiko.md`)

**Status:** Accepted
**Context:** The original mandate YAML files (`mandate-agent.yaml`, `mandate-kimiko-agent.yaml`) set `agent.system_prompt_path` to the YAML file itself (e.g. `mandate-kimiko-agent.yaml`). Kimi CLI 1.46.0 expects `system_prompt_path` to resolve to a real system prompt text file (`.md` or `.txt`), not to the agent spec YAML that contains it. This self-reference caused the mandate prompt to never actually load as the system prompt, making the `kimiko` activation flow described in the README ineffective.

**Decision:** Extract the system prompt text into a separate markdown file at `config/system-prompts/kimiko.md`, installed to `~/.kimi/system-prompts/kimiko.md`. Both mandate YAML files now reference:
```yaml
system_prompt_path: system-prompts/kimiko.md
```
The validator (`validate_mandate_paths` in `validator/validate_kimi.py`) now rejects `system_prompt_path` values that are `.yaml`/`.yml` files or that self-reference the mandate file itself. The `make verify` target also checks that `system-prompts/kimiko.md` is present post-install.

**Rationale:**
- Agent spec YAML and system prompt text serve different purposes and should be decoupled.
- The CLI loader only reads `system_prompt_path` as an external file path; inline `system_prompt:` in the YAML is not sufficient.
- Validator guard prevents this regression from returning.

**Consequences:**
- (+) `kimiko` activation now works as documented in the README.
- (+) Validator catches self-referential or YAML system_prompt_path errors.
- (-) Additional file in the repository; `make sync` does not apply (prompt is not mirrored).
- (-) Existing installations need the prompt file to be installed alongside updated mandate YAMLs.
