# Kimi CLI Configuration Validator v1.0.0

Validates `.kimi` directory configuration files for structural integrity, security posture, cross-reference consistency, and mandate compliance.

## Scope

| File | Type | Validates |
|------|------|-----------|
| `config.toml` | TOML | Schema, cross-references (models ↔ providers), OAuth paths |
| `kimi.toml` | TOML | Schema, cross-references (same as config) |
| `kimi.json` | JSON | Schema, UUIDs, directory existence |
| `mandate-agent.yaml` | YAML | Schema, referenced file paths |
| `mandate-kimiko-agent.yaml` | YAML | Schema, referenced file paths |
| `credentials/*.json` | JSON | Schema, file permissions (must be 0o600) |

## Security Checks

- **Credential permissions**: Credential files must not be world-readable (mode `0o600`).
- **Secret scanning**: Non-credential files are heuristically scanned for leaked API keys, JWTs, and hardcoded passwords.
- **AGENTS.md presence**: Ensures the directory has agent guidance.
- **Device ID permissions**: Ensures `device_id` is not world-readable.

## Installation

```bash
cd ~/.kimi/validator
pip install -r requirements.txt
# Python 3.11+ has built-in tomllib; for 3.10 or earlier:
pip install tomli
```

## Usage

```bash
# Validate entire .kimi directory
python validate_kimi.py all ~/.kimi

# Validate individual files
python validate_kimi.py config ~/.kimi/config.toml
python validate_kimi.py registry ~/.kimi/kimi.json
python validate_kimi.py mandate ~/.kimi/mandate-agent.yaml
python validate_kimi.py credentials ~/.kimi/credentials/kimi-code.json

# Run security checks only
python validate_kimi.py security ~/.kimi

# Validate zero-blocker Mandate kimiko compliance
python validate_kimi.py compliance ~/.kimi
```

## Makefile Targets

```bash
make all             # Validate + test + lint
make validate        # Full ~/.kimi validation
make test            # pytest suite
make validate-config      # config.toml only
make validate-registry    # kimi.json only
make validate-mandates    # mandate YAML files
make validate-credentials # credentials JSON
make security        # Security checks only
make compliance      # Zero-blocker compliance checks
make lint            # Python linter (ruff)
```

## Tests

- `tests/test_validator.py` — Core unit tests (schema loading, config/registry/credentials/mandate validation, security checks, compliance, fixtures)
- `tests/test_install_integration.py` — Integration tests for Makefile install/uninstall targets

## Schemas

All JSON Schemas live in `schemas/` and use Draft 2020-12:

- `config-schema.json` — `config.toml` / `kimi.toml`
- `kimi-json-schema.json` — `kimi.json`
- `mandate-schema.json` — `mandate-*.yaml`
- `credentials-schema.json` — `credentials/*.json`

## Exit Codes

| Code | Meaning |
|------|---------|
| 0 | All validations passed |
| 1 | Validation errors found |
| 2 | Usage / argument error |

## Extending

Add new cross-reference checks in `validate_config_crossrefs()` or new security heuristics in `scan_for_secrets()`.
