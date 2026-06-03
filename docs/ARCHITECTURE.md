# Architecture Decision Records (ADRs)

This document captures the key design decisions in the Kimi Pentest repository and the reasoning behind them.

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

**Decision:** Detect WSL by grepping `uname -r` for `microsoft` or `WSL`. This is the standard, most reliable heuristic.

**Consequences:**
- (+) Single-line shell check, no external dependencies.
- (-) If Microsoft changes the kernel release string, detection could break.

---

## ADR-003: Makefile `max()` Exit Code Aggregation

**Status:** Accepted
**Context:** Validators must return a single exit code.

**Decision:** Aggregate with `overall = max(overall, rc)`.

---

## ADR-004: Four-Layer Mandate Enforcement Mesh

**Status:** Accepted
**Context:** Pentest mandates require absolute, irreversible enforcement. A single point of failure is unacceptable.

**Decision:** Implement four interlocking layers:

1. **Primary Runtime Config** (`config.toml`) — Live configuration loaded on every CLI startup.
2. **Mirror Config** (`kimi.toml`) — Synchronized backup that serves as a fallback.
3. **Mandate Agent Specs** (`mandate-agent.yaml`, `mandate-pentest-agent.yaml`) — YAML agent specifications that inject the zero-blocker system prompt into every session.
4. **Shell Integration** (`*.sh`, `*.ps1`) — Enforces mandate at the OS shell level before the CLI even starts.

Each layer cross-references the others. No single file operates in isolation.

**Consequences:**
- (+) Structural impossibility of accidental deactivation.
- (-) Higher maintenance burden; all four layers must be kept in sync.

---

## ADR-005: Platform-Gated Makefile Targets

**Status:** Accepted
**Context:** Kimi Pentest supports macOS, Linux, WSL, Git Bash, and native PowerShell.

**Decision:** Use `PLATFORM` auto-detection and gate targets.

---

## ADR-006: `HOME_FWD` Pre-Computation

**Status:** Accepted
**Context:** Template substitution for `kimi.json`.

**Decision:** Compute `HOME_FWD` once at Makefile parse time.

---

## ADR-007: Validator Schema Hierarchy

**Status:** Accepted
**Context:** Need both structural and compliance validation.

**Decision:** Maintain two schema files per config type:

| File | Purpose | `additionalProperties` |
|---|---|---|
| `config-schema.json` | Structural validation | `true` |
| `config-zero-blocker-schema.json` | Mandate compliance | `true` |
| `mandate-schema.json` | Structural validation | `false` |
| `mandate-zero-blocker-schema.json` | Mandate compliance | `false` |

---

## ADR-008: Non-Blocking Compliance in `make check`

**Status:** Accepted
**Context:** `make check` runs both structural and compliance validation.

**Decision:** Compliance step is advisory in development; `|| true`.
