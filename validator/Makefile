# Kimi CLI Configuration Validator Makefile

PYTHON ?= $(shell command -v python3 2>/dev/null || command -v python 2>/dev/null || echo python3)

.PHONY: all test validate lint help

all: validate test

test:
	$(PYTHON) -m pytest tests/ -v

KIMI_DIR := $(HOME)/.kimi

validate:
	@if [ ! -d "$(KIMI_DIR)" ]; then echo "$(KIMI_DIR) does not exist. Run 'make install' first."; exit 1; fi
	$(PYTHON) validate_kimi.py all $(KIMI_DIR)

validate-config:
	@if [ ! -d "$(KIMI_DIR)" ]; then echo "$(KIMI_DIR) does not exist. Run 'make install' first."; exit 1; fi
	$(PYTHON) validate_kimi.py config $(KIMI_DIR)/config.toml

validate-registry:
	@if [ ! -d "$(KIMI_DIR)" ]; then echo "$(KIMI_DIR) does not exist. Run 'make install' first."; exit 1; fi
	$(PYTHON) validate_kimi.py registry $(KIMI_DIR)/kimi.json

validate-mandates:
	@if [ ! -d "$(KIMI_DIR)" ]; then echo "$(KIMI_DIR) does not exist. Run 'make install' first."; exit 1; fi
	$(PYTHON) validate_kimi.py mandate $(KIMI_DIR)/mandate-agent.yaml
	$(PYTHON) validate_kimi.py mandate $(KIMI_DIR)/mandate-kimiko-agent.yaml

validate-credentials:
	@if [ ! -d "$(KIMI_DIR)" ]; then echo "$(KIMI_DIR) does not exist. Run 'make install' first."; exit 1; fi
	$(PYTHON) validate_kimi.py credentials $(KIMI_DIR)/credentials/kimi-code.json

security:
	@if [ ! -d "$(KIMI_DIR)" ]; then echo "$(KIMI_DIR) does not exist. Run 'make install' first."; exit 1; fi
	$(PYTHON) validate_kimi.py security $(KIMI_DIR)

compliance:
	@if [ ! -d "$(KIMI_DIR)" ]; then echo "$(KIMI_DIR) does not exist. Run 'make install' first."; exit 1; fi
	$(PYTHON) validate_kimi.py compliance $(KIMI_DIR)

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
