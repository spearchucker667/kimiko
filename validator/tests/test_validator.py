"""Tests for the Kimi CLI Configuration Validator."""

import json
import os
import stat
import sys
import tempfile
from pathlib import Path

import pytest
import yaml

# Allow importing from parent directory
sys_path = str(Path(__file__).parent.parent)
if sys_path not in sys.path:
    sys.path.insert(0, sys_path)

from validate_kimi import (
    check_file_permissions,
    load_schema,
    scan_for_secrets,
    validate_against_schema,
    validate_config_crossrefs,
    validate_registry_paths,
)


class TestSchemaLoading:
    def test_all_schemas_load(self):
        for name in [
            "config-schema.json",
            "kimi-json-schema.json",
            "mandate-schema.json",
            "credentials-schema.json",
        ]:
            schema = load_schema(name)
            assert "$schema" in schema
            assert "type" in schema


class TestConfigValidation:
    def test_valid_config(self, tmp_path):
        cfg = {
            "default_model": "kimi-code/kimi-for-coding",
            "default_thinking": True,
            "providers": {
                "managed:kimi-code": {
                    "type": "kimi",
                    "base_url": "https://api.kimi.com/coding/v1",
                }
            },
            "models": {
                "kimi-code/kimi-for-coding": {
                    "provider": "managed:kimi-code",
                    "model": "kimi-for-coding",
                    "max_context_size": 262144,
                }
            },
            "loop_control": {
                "max_steps_per_turn": 1000,
                "max_retries_per_step": 3,
            },
            "background": {
                "max_running_tasks": 4,
            },
        }
        schema = load_schema("config-schema.json")
        valid, errors = validate_against_schema(cfg, schema, "test")
        assert valid, errors

    def test_missing_required_field_in_model(self, tmp_path):
        cfg = {
            "default_model": "kimi-code/kimi-for-coding",
            "providers": {
                "managed:kimi-code": {"type": "kimi", "base_url": "https://api.kimi.com/coding/v1"}
            },
            "models": {
                "kimi-code/kimi-for-coding": {
                    "provider": "managed:kimi-code",
                    # missing "model" and "max_context_size"
                }
            },
            "loop_control": {"max_steps_per_turn": 1, "max_retries_per_step": 0},
            "background": {},
        }
        schema = load_schema("config-schema.json")
        valid, errors = validate_against_schema(cfg, schema, "test")
        assert not valid
        assert any("model" in str(e.message) or "max_context_size" in str(e.message) for e in errors)

    def test_crossref_missing_provider(self, tmp_path):
        cfg = {
            "default_model": "missing-model",
            "models": {
                "missing-model": {"provider": "ghost", "model": "x", "max_context_size": 1}
            },
            "providers": {},
            "loop_control": {"max_steps_per_turn": 1, "max_retries_per_step": 0},
            "background": {},
        }
        errs = validate_config_crossrefs(cfg, tmp_path / "config.toml")
        assert any("ghost" in e for e in errs)


class TestRegistryValidation:
    def test_valid_registry(self):
        data = {
            "work_dirs": [
                {"path": "/tmp", "kaos": "local", "last_session_id": None},
                {
                    "path": "/home",
                    "kaos": "local",
                    "last_session_id": "550e8400-e29b-41d4-a716-446655440000",
                },
            ]
        }
        schema = load_schema("kimi-json-schema.json")
        valid, errors = validate_against_schema(data, schema, "test")
        assert valid, errors

    def test_invalid_uuid(self):
        data = {
            "work_dirs": [
                {"path": "/tmp", "kaos": "local", "last_session_id": "not-a-uuid"}
            ]
        }
        errs = validate_registry_paths(data)
        assert any("invalid UUID" in e for e in errs)


class TestCredentialsValidation:
    def test_valid_credentials(self):
        data = {
            "access_token": "sk-kimi-test-token-1234567890",
            "token_type": "Bearer",
            "expires_at": 1893456000.5,
            "refresh_token": "refresh-123",
            "scope": "all",
        }
        schema = load_schema("credentials-schema.json")
        valid, errors = validate_against_schema(data, schema, "test")
        assert valid, errors

    def test_missing_access_token(self):
        data = {"token_type": "Bearer"}
        schema = load_schema("credentials-schema.json")
        valid, errors = validate_against_schema(data, schema, "test")
        assert not valid


class TestSecurityChecks:
    def test_world_readable_file_flagged(self, tmp_path):
        f = tmp_path / "secret.json"
        f.write_text("{}")
        os.chmod(f, 0o644)
        errs = check_file_permissions(f)
        assert len(errs) == 1
        assert "too permissive" in errs[0]

    def test_restrictive_file_passes(self, tmp_path):
        f = tmp_path / "secret.json"
        f.write_text("{}")
        os.chmod(f, 0o600)
        errs = check_file_permissions(f)
        assert len(errs) == 0

    def test_secret_scanning_finds_api_key(self):
        text = 'api_key = "sk-kimi-12345678901234567890abcdef"'
        findings = scan_for_secrets(text, Path("config.toml"))
        assert len(findings) == 1
        assert "API key" in findings[0]

    def test_secret_scanning_clean(self):
        text = "theme = \"dark\"\nshow_thinking_stream = true"
        findings = scan_for_secrets(text, Path("config.toml"))
        assert len(findings) == 0


class TestMandateValidation:
    def test_valid_mandate(self):
        data = {
            "version": 1,
            "agent": {
                "name": "Test Agent",
                "designation": "Test",
                "tools": ["kimi_cli.tools.shell:Shell"],
                "authorized_settings": [
                    {"category": "HARM_CATEGORY_DANGEROUS_CONTENT", "threshold": "BLOCK_NONE"}
                ],
            },
        }
        schema = load_schema("mandate-schema.json")
        valid, errors = validate_against_schema(data, schema, "test")
        assert valid, errors

    def test_missing_tools(self):
        data = {"version": 1, "agent": {"name": "Test", "designation": "Test"}}
        schema = load_schema("mandate-schema.json")
        valid, errors = validate_against_schema(data, schema, "test")
        assert not valid
