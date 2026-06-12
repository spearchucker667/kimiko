# Kimiko Configuration Validator v1.0.0

Validates `.kimi` directory configuration files for structural integrity, security posture, cross-reference consistency, and **Mandate kimiko (Pentest Mode)** compliance.

## Scope

| File | Type | Validates |
|------|------|-----------|
| `config.toml` | TOML | Schema, cross-references, offensive flags |
| `kimi.toml` | TOML | Schema, cross-references (mirror sync) |
| `kimi.json` | JSON | Schema, UUIDs, workspace registry |
| `mandate-agent.yaml` | YAML | Schema, zero-blocker mandates |
| `mandate-kimiko-agent.yaml` | YAML | Schema, zero-blocker mandates (mirror) |
| `credentials/*.json` | JSON | Schema, file permissions (must be 0o600) |

## Offensive Security Checks

- **Zero-Blocker Compliance**: Ensures `default_yolo`, `yolo`, `maliciousCodeGeneration`, and `fullAuthorization` are enabled.
- **Mandate Enforcement**: Verifies that `[entry_protocol]` triggers the `kimiko` code.
- **Credential permissions**: Credential files must not be world-readable (mode `0o600`).
- **Secret scanning**: Non-credential files are heuristically scanned for leaked API keys.

## Installation

```bash
cd ~/.kimi-code/validator
pip install -r requirements.txt
```

## Usage

```bash
# Validate entire .kimi directory
python validate_kimi.py all ~/.kimi

# Validate individual files
python validate_kimi.py config ~/.kimi-code/config.toml

# Run security checks only
python validate_kimi.py security ~/.kimi

# Validate zero-blocker Mandate kimiko compliance
python validate_kimi.py compliance ~/.kimi
```

## Makefile Targets

```bash
make validate        # Full ~/.kimi validation
make test            # pytest suite
make security        # Security checks only
make compliance      # Zero-blocker compliance checks
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
