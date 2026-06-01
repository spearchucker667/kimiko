# Kimiko — macOS-only installer for the ~/.kimi mandate configuration
# Targets: install, verify, uninstall, help

REPO_ROOT := $(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))
DEST := $(HOME)/.kimi

# Source files to sync from repo → ~/.kimi
CONFIG_FILES := \
	AGENTS.md \
	config.toml \
	kimi.toml \
	mandate-agent.yaml \
	mandate-kimiko-agent.yaml \
	activate-mandate.sh \
	kimi-wrapper.sh \
	kimi-shell-integration.sh \
	launch-with-mandate.sh \
	latest_version.txt

.PHONY: all install verify uninstall help

all: help

help:
	@echo "Kimiko — ~/.kimi mandate installer (macOS)"
	@echo ""
	@echo "  make install    Full idempotent setup into ~/.kimi"
	@echo "  make verify     Confirm files landed and key strings present"
	@echo "  make uninstall  Remove installed Kimiko files (preserves secrets)"
	@echo "  make help       Show this help text"

install: $(DEST)/kimi.json $(DEST)/config.toml $(DEST)/kimi.toml \
	$(DEST)/mandate-agent.yaml $(DEST)/mandate-kimiko-agent.yaml \
	$(DEST)/activate-mandate.sh $(DEST)/kimi-wrapper.sh \
	$(DEST)/kimi-shell-integration.sh $(DEST)/launch-with-mandate.sh \
	$(DEST)/latest_version.txt \
	$(DEST)/validator/Makefile $(DEST)/validator/README.md \
	$(DEST)/validator/validate_kimi.py \
	$(DEST)/validator/schemas/config-schema.json \
	$(DEST)/validator/schemas/config-zero-blocker-schema.json \
	$(DEST)/validator/schemas/credentials-schema.json \
	$(DEST)/validator/schemas/kimi-json-schema.json \
	$(DEST)/validator/schemas/mandate-schema.json \
	$(DEST)/validator/schemas/mandate-zero-blocker-schema.json \
	$(DEST)/validator/tests/test_validator.py
	@echo ""
	@echo "✓ Kimiko installed to $(DEST)"
	@echo "  Run: source $(DEST)/activate-mandate.sh"
	@echo "  Or : $(DEST)/launch-with-mandate.sh"

# Idempotent copy rule for all flat config files
$(DEST)/%: $(REPO_ROOT)/%
	@mkdir -p $(dir $@)
	cp -f $< $@
	@if [ -f "$@" ] && echo "$@" | grep -qE '\.(sh)$$'; then chmod +x "$@"; fi
	@if [ -f "$@" ] && echo "$@" | grep -qE 'config\.toml|kimi\.toml|mandate.*\.yaml'; then chmod 600 "$@"; fi

# Template render: kimi.json
$(DEST)/kimi.json: $(REPO_ROOT)/kimi.json.template
	@mkdir -p $(dir $@)
	sed 's|<YOUR_HOME_DIR>|$(HOME)|g' $< > $@
	chmod 600 $@

# Uninstall: remove only the files we own (never touch credentials, logs, sessions, etc.)
uninstall:
	@echo "Removing Kimiko-managed files from $(DEST) ..."
	@for f in $(CONFIG_FILES); do \
		rm -f "$(DEST)/$$f"; \
	done
	@rm -f $(DEST)/kimi.json
	@rm -rf $(DEST)/validator
	@echo "✓ Uninstalled. User secrets in credentials/, logs/, sessions/ were NOT touched."

verify:
	@echo "Verifying Kimiko installation in $(DEST) ..."
	@fail=0; \
	for f in $(CONFIG_FILES); do \
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
	if [ "$$fail" -eq 0 ]; then \
		echo ""; echo "✓ All verification checks passed."; \
	else \
		echo ""; echo "✗ Verification failed."; exit 1; \
	fi
