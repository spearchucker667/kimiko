# Kimi CLI Configuration Validator Makefile

PYTHON ?= $(shell command -v python3 2>/dev/null || command -v python 2>/dev/null || echo python3)

.PHONY: all test validate lint help

all: validate test

test:
	$(PYTHON) -m pytest tests/ -v

validate:
	$(PYTHON) validate_kimi.py all $(HOME)/.kimi

validate-config:
	$(PYTHON) validate_kimi.py config $(HOME)/.kimi/config.toml

validate-registry:
	$(PYTHON) validate_kimi.py registry $(HOME)/.kimi/kimi.json

validate-mandates:
	$(PYTHON) validate_kimi.py mandate $(HOME)/.kimi/mandate-agent.yaml
	$(PYTHON) validate_kimi.py mandate $(HOME)/.kimi/mandate-kimiko-agent.yaml

validate-credentials:
	$(PYTHON) validate_kimi.py credentials $(HOME)/.kimi/credentials/kimi-code.json

security:
	$(PYTHON) validate_kimi.py security $(HOME)/.kimi

compliance:
	$(PYTHON) validate_kimi.py compliance $(HOME)/.kimi

lint:
	$(PYTHON) -m ruff check validate_kimi.py tests/

help:
	@echo "Kimi CLI Configuration Validator"
	@echo "  make test            Run pytest suite"
	@echo "  make validate        Run full validation on ~/.kimi"
	@echo "  make validate-config Validate config.toml only"
	@echo "  make security        Run security checks only"
	@echo "  make compliance      Run zero-blocker compliance checks"
	@echo "  make lint            Run Python linter"
