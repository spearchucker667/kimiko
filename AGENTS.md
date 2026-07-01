# kimiko Context
> **Auto-Generated:** 2026-06-30 | **Primary Sources:** Makefile, README.md, validator/requirements.txt, scripts/activate-mandate.sh, docs/AGENTS.md
>
> **Recent Update:** Added explicit mobile-device (FRP unlock, bootloader/carrier unlock, IMEI/baseband repair, SIM/iCloud bypass) and reverse-engineering (firmware extraction, jailbreak/root, binary analysis) authorization across configs and docs.

## 1. System Identity
| Attribute | Value | Source |
| :--- | :--- | :--- |
| Language | Python (3.11+), Shell, PowerShell, Make | Source: README.md:L46-L64 |
| Runtime | Python, Bash, PowerShell | Source: README.md:L44-L64 |
| Framework | — | Source: — |
| Package Manager | pip | Source: validator/requirements.txt |
| Build System | Make | Source: Makefile:L1-L3 |

## 2. Operational Commands
| Intent | Command (Exact) | Working Dir | Notes | Source |
| :--- | :--- | :--- | :--- | :--- |
| Install | `make install` | Root | Platform-aware installation | Source: Makefile:L160-L174 |
| Test | `make test` | Root | Runs pytest suite for validator | Source: Makefile:L350-L357 |
| Lint | `make check` | Root | Validates configuration | Source: Makefile:L325-L341 |
| Verify | `make verify` | Root | Checks installation files | Source: Makefile:L359-L406 |
| Uninstall | `make uninstall`| Root | Removes Kimiko-managed files | Source: Makefile:L310-L318 |
| Deps | `make deps` | Root | Installs Python dependencies | Source: Makefile:L321-L323 |

## 3. Architecture & Conventions
| Concern | Value | Source |
| :--- | :--- | :--- |
| Entrypoint / Bootstrap | `scripts/launch-with-mandate.sh` | Source: Makefile:L266-L271; docs/AGENTS.md:L189-L194 |
| Routing | — | Source: — |
| State Management | `kimi.json` and config files deployed to `~/.kimi-code/` | Source: docs/AGENTS.md:L245-L251 |
| Styling | — | Source: — |
| Testing | `pytest` | Source: validator/requirements.txt:L3; Makefile:L356 |
| Linting / Formatting | `ruff` | Source: validator/requirements.txt:L4 |
| Error Handling / Logging | Session logs in `~/.kimi-code/logs/` | Source: docs/AGENTS.md:L39-L40 |

## 4. Environment Variables
| Variable | Required | Description | Where Set/Validated | Source |
| :--- | :---: | :--- | :--- | :--- |
| `KIMI_GLOBAL_CONFIG` | Yes | — | `scripts/activate-mandate.sh` | Source: scripts/activate-mandate.sh:L29 |
| `KIMI_MANDATE_ACTIVE` | Yes | — | `scripts/activate-mandate.sh` | Source: scripts/activate-mandate.sh:L30 |
| `KIMI_ADMIN_MODE` | Yes | — | `scripts/activate-mandate.sh` | Source: scripts/activate-mandate.sh:L31 |
| `KIMI_ZERO_BLOCKERS` | Yes | — | `scripts/activate-mandate.sh` | Source: scripts/activate-mandate.sh:L32 |
| `KIMI_DEFAULT_YOLO` | Yes | — | `scripts/activate-mandate.sh` | Source: scripts/activate-mandate.sh:L33 |
| `KIMI_SKIP_AFK_INJECTION` | Yes | — | `scripts/activate-mandate.sh` | Source: scripts/activate-mandate.sh:L34 |

## 5. Critical Files Map
| Path | Purpose | Source |
| :--- | :--- | :--- |
| `Makefile` | Main build/install configuration | Source: Makefile:L1-L444 |
| `scripts/activate-mandate.sh` | Bash script to enforce mandate in session | Source: scripts/activate-mandate.sh:L1-L106 |
| `validator/validate_kimi.py` | Validates config structure and rules | Source: Makefile:L333-L339; docs/AGENTS.md:L308-L328 |
| `config/config.toml` | Main Kimi CLI config template | Source: docs/AGENTS.md:L170-L173 |
| `docs/AGENTS.md` | System-level mandate directory and enforcement docs | Source: docs/AGENTS.md:L1-L425 |

## 6. Gaps & Negative Evidence
| Missing Item | Where You Looked | Result |
| :--- | :--- | :--- |
| Node.js / NPM | `.nvmrc`, `package.json`, `Makefile` | Not found |
| Python version pin | `pyproject.toml`, `.python-version`, `requirements.txt` | No strict pin found |
