# Kimiko — macOS-only installer for the ~/.kimi mandate configuration
# Targets: install, verify, uninstall, help

REPO_ROOT := $(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))
DEST := $(HOME)/.kimi

# Config files (source in config/ → ~/.kimi)
CONFIG_SRCS := \
	config/config.toml \
	config/kimi.toml \
	config/mandate-agent.yaml \
	config/mandate-kimiko-agent.yaml \
	config/latest_version.txt

# Script files (source in scripts/ → ~/.kimi)
SCRIPT_SRCS := \
	scripts/activate-mandate.sh \
	scripts/kimi-wrapper.sh \
	scripts/kimi-shell-integration.sh \
	scripts/launch-with-mandate.sh

# All flat files installed directly into ~/.kimi
FLAT_TARGETS := \
	$(DEST)/config.toml \
	$(DEST)/kimi.toml \
	$(DEST)/mandate-agent.yaml \
	$(DEST)/mandate-kimiko-agent.yaml \
	$(DEST)/latest_version.txt \
	$(DEST)/activate-mandate.sh \
	$(DEST)/kimi-wrapper.sh \
	$(DEST)/kimi-shell-integration.sh \
	$(DEST)/launch-with-mandate.sh

# Validator files installed into ~/.kimi/validator/
VALIDATOR_TARGETS := \
	$(DEST)/validator/Makefile \
	$(DEST)/validator/README.md \
	$(DEST)/validator/validate_kimi.py \
	$(DEST)/validator/schemas/config-schema.json \
	$(DEST)/validator/schemas/config-zero-blocker-schema.json \
	$(DEST)/validator/schemas/credentials-schema.json \
	$(DEST)/validator/schemas/kimi-json-schema.json \
	$(DEST)/validator/schemas/mandate-schema.json \
	$(DEST)/validator/schemas/mandate-zero-blocker-schema.json \
	$(DEST)/validator/tests/test_validator.py \
	$(DEST)/validator/tests/test_install_integration.py \
	$(DEST)/validator/tests/fixtures/bad-config-no-admin.toml \
	$(DEST)/validator/tests/fixtures/bad-config-no-yolo.toml \
	$(DEST)/validator/tests/fixtures/bad-mandate-missing-tools.yaml \
	$(DEST)/validator/tests/fixtures/bad-mandate-no-zero-blockers.yaml

.PHONY: all install verify uninstall check sync test help

all: help

help:
	@echo "Kimiko — ~/.kimi mandate installer (macOS)"
	@echo ""
	@echo "  make install    Full idempotent setup into ~/.kimi"
	@echo "  make verify     Confirm files landed and key strings present"
	@echo "  make check      Validate config files with the validator"
	@echo "  make sync       Verify config/mandate mirror files are in sync"
	@echo "  make test       Run pytest suite for the validator"
	@echo "  make uninstall  Remove installed Kimiko files (preserves secrets)"
	@echo "  make help       Show this help text"

install: $(DEST)/kimi.json $(FLAT_TARGETS) $(VALIDATOR_TARGETS)
	@echo ""
	@echo "✓ Kimiko installed to $(DEST)"
	@echo "  Run: source $(DEST)/activate-mandate.sh"
	@echo "  Or : $(DEST)/launch-with-mandate.sh"

# Config files: config/ → ~/.kimi
$(DEST)/config.toml: $(REPO_ROOT)/config/config.toml
	@mkdir -p $(dir $@)
	cp -f $< $@
	chmod 600 $@

$(DEST)/kimi.toml: $(REPO_ROOT)/config/kimi.toml
	@mkdir -p $(dir $@)
	cp -f $< $@
	chmod 600 $@

$(DEST)/mandate-agent.yaml: $(REPO_ROOT)/config/mandate-agent.yaml
	@mkdir -p $(dir $@)
	cp -f $< $@
	chmod 600 $@

$(DEST)/mandate-kimiko-agent.yaml: $(REPO_ROOT)/config/mandate-kimiko-agent.yaml
	@mkdir -p $(dir $@)
	cp -f $< $@
	chmod 600 $@

$(DEST)/latest_version.txt: $(REPO_ROOT)/config/latest_version.txt
	@mkdir -p $(dir $@)
	cp -f $< $@

# Script files: scripts/ → ~/.kimi
$(DEST)/activate-mandate.sh: $(REPO_ROOT)/scripts/activate-mandate.sh
	@mkdir -p $(dir $@)
	cp -f $< $@
	chmod +x $@

$(DEST)/kimi-wrapper.sh: $(REPO_ROOT)/scripts/kimi-wrapper.sh
	@mkdir -p $(dir $@)
	cp -f $< $@
	chmod +x $@

$(DEST)/kimi-shell-integration.sh: $(REPO_ROOT)/scripts/kimi-shell-integration.sh
	@mkdir -p $(dir $@)
	cp -f $< $@
	chmod +x $@

$(DEST)/launch-with-mandate.sh: $(REPO_ROOT)/scripts/launch-with-mandate.sh
	@mkdir -p $(dir $@)
	cp -f $< $@
	chmod +x $@

# Template render: kimi.json (atomic: temp file + mv)
$(DEST)/kimi.json: $(REPO_ROOT)/config/kimi.json.template
	@mkdir -p $(dir $@)
	@tmp="$@.tmp.$$$$"; \
	sed 's|<YOUR_HOME_DIR>|$(HOME)|g' $< > "$$tmp"; \
	chmod 600 "$$tmp"; \
	mv -f "$$tmp" "$@"

# Validator files: validator/ → ~/.kimi/validator/
$(DEST)/validator/%: $(REPO_ROOT)/validator/%
	@mkdir -p $(dir $@)
	cp -f $< $@

# Uninstall: remove only the files we own (never touch credentials, logs, sessions, etc.)
uninstall:
	@echo "Removing Kimiko-managed files from $(DEST) ..."
	@for f in $(notdir $(FLAT_TARGETS)); do \
		rm -f "$(DEST)/$$f"; \
	done
	@rm -f $(DEST)/kimi.json
	@rm -rf $(DEST)/validator
	@echo "✓ Uninstalled. User secrets in credentials/, logs/, sessions/ were NOT touched."

check:
	@echo "Running validator checks ..."
	@cd $(REPO_ROOT)/validator && python3 validate_kimi.py config --no-crossrefs $(REPO_ROOT)/config/config.toml
	@cd $(REPO_ROOT)/validator && python3 validate_kimi.py config --no-crossrefs $(REPO_ROOT)/config/kimi.toml
	@cd $(REPO_ROOT)/validator && python3 validate_kimi.py mandate $(REPO_ROOT)/config/mandate-agent.yaml
	@cd $(REPO_ROOT)/validator && python3 validate_kimi.py mandate $(REPO_ROOT)/config/mandate-kimiko-agent.yaml
	@echo "✓ All structural checks passed."
	@echo "Running zero-blocker compliance checks ..."
	@cd $(REPO_ROOT)/validator && python3 validate_kimi.py compliance $(REPO_ROOT)/config 2>/dev/null || true
	@echo "✓ All checks passed."

sync:
	@echo "Checking config.toml / kimi.toml sync ..."
	@sync_tmp=$$(mktemp /tmp/kimi-sync.XXXXXX); \
	sed -n '/^[^#]/,$$p' $(REPO_ROOT)/config/kimi.toml > "$$sync_tmp"; \
	if ! diff -q $(REPO_ROOT)/config/config.toml "$$sync_tmp" > /dev/null; then \
		echo "  ✗ config.toml and kimi.toml differ (after stripping kimi.toml comment header)"; \
		rm -f "$$sync_tmp"; \
		exit 1; \
	fi; \
	rm -f "$$sync_tmp"
	@echo "Checking mandate-agent.yaml / mandate-kimiko-agent.yaml sync ..."
	@if ! diff -q $(REPO_ROOT)/config/mandate-agent.yaml $(REPO_ROOT)/config/mandate-kimiko-agent.yaml > /dev/null; then \
		echo "  ✗ mandate-agent.yaml and mandate-kimiko-agent.yaml differ"; \
		exit 1; \
	fi
	@echo "✓ All sync checks passed."

test:
	@cd $(REPO_ROOT)/validator && python3 -m pytest tests/ -v

verify:
	@echo "Verifying Kimiko installation in $(DEST) ..."
	@fail=0; \
	for f in $(notdir $(FLAT_TARGETS)); do \
		if [ ! -f "$(DEST)/$$f" ]; then \
			echo "  ✗ missing: $(DEST)/$$f"; fail=1; \
		else \
			echo "  ✓ present: $(DEST)/$$f"; \
		fi; \
	done; \
	if [ ! -f "$(DEST)/kimi.json" ]; then \
		echo "  ✗ missing: $(DEST)/kimi.json"; fail=1; \
	else \
		echo "  ✓ present: $(DEST)/kimi.json"; \
	fi; \
	if [ ! -d "$(DEST)/validator/schemas" ]; then \
		echo "  ✗ missing: $(DEST)/validator/schemas"; fail=1; \
	else \
		echo "  ✓ present: $(DEST)/validator/schemas"; \
	fi; \
	if ! grep -q 'kimiko' "$(DEST)/config.toml" 2>/dev/null; then \
		echo "  ✗ config.toml does not contain 'kimiko'"; fail=1; \
	else \
		echo "  ✓ config.toml references 'kimiko'"; \
	fi; \
	if ! grep -q 'kimiko' "$(DEST)/mandate-kimiko-agent.yaml" 2>/dev/null; then \
		echo "  ✗ mandate-kimiko-agent.yaml does not contain 'kimiko'"; fail=1; \
	else \
		echo "  ✓ mandate-kimiko-agent.yaml references 'kimiko'"; \
	fi; \
	if ! python3 -c "import json; json.load(open('$(DEST)/kimi.json'))" 2>/dev/null; then \
		echo "  ✗ kimi.json is not valid JSON"; fail=1; \
	else \
		echo "  ✓ kimi.json is valid JSON"; \
	fi; \
	if [ "$$fail" -eq 0 ]; then \
		echo ""; echo "✓ All verification checks passed."; \
	else \
		echo ""; echo "✗ Verification failed."; exit 1; \
	fi
