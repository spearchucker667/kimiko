# RUP Protocol v3.0.0

> Repository Upgrade Protocol — AI Maintainer Mode
> Adapted for the Kimiko project.

## Quick Start

RUP is a 4-phase protocol for upgrading repositories:

1. **DISCOVERY** → Analyze repo, identify gaps
2. **PLANNING** → Prioritize work, select items
3. **EXECUTION** → Implement changes, run tests
4. **VERIFICATION** → Validate, report, handoff

## Scaling Tier: Small

This repository falls into the **small** tier:

- Files: ~60–90
- LOC: ~4,000–6,000
- Contributors: 1–2
- Platforms: macOS, Linux, Windows (Git Bash / WSL / PowerShell)

Per RUP scaling guidelines, the following are included:

| Element | Status |
|---------|--------|
| README.md | ✅ Complete |
| LICENSE | ✅ MIT |
| .gitignore | ✅ Present |
| CONTRIBUTING.md | ✅ Present |
| SECURITY.md | ✅ Present |
| Pre-commit hooks | ✅ `.pre-commit-config.yaml` |
| PowerShell scripts | ✅ `scripts/*.ps1` (4 files) |
| Windows install guide | ✅ `docs/INSTALL-WINDOWS.md` |
| CI with lint + test | ✅ `.github/workflows/ci.yml` (macOS, Ubuntu, Windows matrix) |
| CODEOWNERS | ✅ Present |
| Issue/PR templates | ✅ Present |
| Dependabot/Renovate | ✅ `.github/dependabot.yml` |

Skipped (medium+ tier only):
- ADRs
- Advanced CI (matrix, caching)
- Chaos engineering

## Kimiko-Specific Verification Commands

```bash
# macOS / Linux / WSL / Git Bash
make install
make test
make check
make sync
python3 validator/validate_kimi.py security ~/.kimi
python3 validator/validate_kimi.py compliance ~/.kimi
python3 validator/validate_kimi.py all ~/.kimi
```

```powershell
# PowerShell
make install
python -m pytest validator/tests/ -v
python validator/validate_kimi.py security $env:USERPROFILE\.kimi
python validator/validate_kimi.py compliance $env:USERPROFILE\.kimi
python validator/validate_kimi.py all $env:USERPROFILE\.kimi
```

## Conventional Commits

This project follows Conventional Commits 1.0.0:

```
<type>(<scope>): <subject>

[body]

[footer]
```

Types: `fix`, `feat`, `docs`, `style`, `refactor`, `perf`, `test`, `build`, `ci`, `chore`, `revert`

## Rollback Procedure

```bash
# Uninstall from ~/.kimi
make uninstall

# Or revert specific file
make verify  # shows what's installed
```

---

*This document is a project-local adaptation of the RUP Protocol v3.0.0.*
