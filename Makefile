# Kimiko — Cross-platform installer for the ~/.kimi-code mandate configuration
# Platforms: macOS, Linux, WSL, Git Bash (MINGW), PowerShell (Windows)
# Targets: install, verify, uninstall, help

REPO_ROOT := $(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))

# ── Python for cross-platform template rendering ─────────────────────────────
PYTHON ?= $(shell command -v python3 2>/dev/null || command -v python 2>/dev/null || echo python3)

# ── Platform Detection ───────────────────────────────────────────────────────
ifeq ($(OS),Windows_NT)
    # Check if running in a Unix-like shell environment on Windows
    # (like Git Bash, MSYS2, Cygwin) by checking if MSYSTEM is set, or if we have a Unix shell.
    UNAME_S := $(shell uname -s 2>/dev/null || echo "")
    ifneq ($(findstring MINGW,$(UNAME_S)),)
        ifdef MSYSTEM
            PLATFORM := gitbash
        else
            PLATFORM := windows
        endif
    else ifneq ($(findstring MSYS,$(UNAME_S)),)
        ifdef MSYSTEM
            PLATFORM := gitbash
        else
            PLATFORM := windows
        endif
    else ifneq ($(findstring CYGWIN,$(UNAME_S)),)
        PLATFORM := gitbash
    else
        PLATFORM := windows
    endif
else
    UNAME_S := $(shell uname -s 2>/dev/null || echo "")
    UNAME_R := $(shell uname -r 2>/dev/null || echo "")

    ifeq ($(UNAME_S),Darwin)
        PLATFORM := macos
    else ifeq ($(UNAME_S),Linux)
        ifneq ($(findstring microsoft,$(UNAME_R)),)
            PLATFORM := wsl
        else ifneq ($(findstring WSL,$(UNAME_R)),)
            PLATFORM := wsl
        else
            PLATFORM := linux
        endif
    else
        PLATFORM := unknown
    endif
endif

# ── Home directory and install destination ───────────────────────────────────
ifeq ($(PLATFORM),windows)
    ifneq ($(strip $(USERPROFILE)),)
        HOME_DIR := $(USERPROFILE)
    else ifneq ($(strip $(HOME)),)
        HOME_DIR := $(HOME)
    else
        HOME_DIR := $(TEMP)
    endif
else ifeq ($(PLATFORM),gitbash)
    ifneq ($(strip $(HOME)),)
        HOME_DIR := $(subst \,/,$(HOME))
    else ifneq ($(strip $(USERPROFILE)),)
        HOME_DIR := $(subst \,/,$(USERPROFILE))
    else
        HOME_DIR := $(subst \,/,$(TEMP))
    endif
else
    HOME_DIR := $(HOME)
endif

ifeq ($(PLATFORM),windows)
    ifdef KIMI_CODE_HOME
        DEST_ABS := $(KIMI_CODE_HOME)
    else
        DEST_ABS := $(HOME_DIR)/.kimi-code
    endif
    # Convert to relative path to prevent Windows drive letter colons from breaking Make parsing.
    # Fallback to absolute path if python command fails or paths are on different drives.
    DEST := $(shell $(PYTHON) -c "import os; print(os.path.relpath(r'$(DEST_ABS)', r'$(REPO_ROOT)').replace('\\\\', '/'))" 2>/dev/null || echo "$(DEST_ABS)")
else
    ifdef KIMI_CODE_HOME
        DEST := $(KIMI_CODE_HOME)
    else
        DEST := $(HOME_DIR)/.kimi-code
    endif
endif

ifeq ($(PLATFORM),$(filter $(PLATFORM),windows gitbash))
    WINDOWS_SCRIPTS := \
        $(DEST)/activate-mandate.ps1 \
        $(DEST)/kimi-wrapper.ps1 \
        $(DEST)/kimi-shell-integration.ps1 \
        $(DEST)/launch-with-mandate.ps1
else
    WINDOWS_SCRIPTS :=
endif

# Pre-compute Linux install target so we don't put ifneq inside a recipe
ifeq ($(PLATFORM),linux)
    ifneq ($(findstring microsoft,$(UNAME_R)),)
        LINUX_INSTALL_TARGET := install-wsl
    else ifneq ($(findstring WSL,$(UNAME_R)),)
        LINUX_INSTALL_TARGET := install-wsl
    else
        LINUX_INSTALL_TARGET := install-linux
    endif
endif

# All flat files installed directly into ~/.kimi-code
FLAT_TARGETS := \
    $(DEST)/config.toml \
    $(DEST)/tui.toml \
    $(DEST)/kimi.toml \
    $(DEST)/mandate-agent.yaml \
    $(DEST)/mandate-kimiko-agent.yaml \
    $(DEST)/latest_version.txt \
    $(DEST)/activate-mandate.sh \
    $(DEST)/kimi-wrapper.sh \
    $(DEST)/kimi-shell-integration.sh \
    $(DEST)/launch-with-mandate.sh \
    $(DEST)/AGENTS.md \
    $(WINDOWS_SCRIPTS)

# Validator files installed into ~/.kimi-code/validator/
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

.PHONY: all install install-windows install-gitbash install-wsl install-macos install-linux verify uninstall check sync test help permissions deps

all: help

help:
	@echo "Kimiko — Offensive Security Configuration for Kimi (Pentest Mode)"
	@echo ""
	@echo "  make install      Platform-aware install (auto-detects OS)"
	@echo "  make install-windows   PowerShell install into %USERPROFILE%\.kimi-code"
	@echo "  make install-gitbash   Git Bash install (chmod is no-op on NTFS)"
	@echo "  make install-wsl       WSL install (native Linux filesystem)"
	@echo "  make install-macos     macOS install (BSD make, chmod enforced)"
	@echo "  make install-linux     Native Linux install"
	@echo "  make verify       Confirm files landed and adversarial mandates are active"
	@echo "  make deps         Install Python dependencies for the validator"
	@echo "  make check        Validate config files for structural and offensive compliance"
	@echo "  make sync         Verify config/mandate mirror files are in sync"
	@echo "  make test         Run pytest suite for the validator"
	@echo "  make uninstall    Remove installed Kimiko files (preserves secrets)"
	@echo "  make permissions  Show Windows ACL guidance (Windows / Git Bash)"
	@echo "  make help         Show this help text"
	@echo ""
	@echo "Detected platform: $(PLATFORM)"
	@echo "Install destination: $(DEST)"

# ── Platform-Aware Install ───────────────────────────────────────────────────
install:
ifeq ($(PLATFORM),windows)
	$(MAKE) install-windows
else ifeq ($(PLATFORM),gitbash)
	$(MAKE) install-gitbash
else ifeq ($(PLATFORM),macos)
	$(MAKE) install-macos
else ifeq ($(PLATFORM),linux)
	$(MAKE) $(LINUX_INSTALL_TARGET)
else ifeq ($(PLATFORM),wsl)
	$(MAKE) install-wsl
else
	@echo "Unknown platform '$(PLATFORM)'. Defaulting to Unix install."
	$(MAKE) install-linux
endif

install-windows: $(DEST)/kimi.json $(FLAT_TARGETS) $(VALIDATOR_TARGETS)
	@echo ""
	@echo "Kimiko installed to $(DEST)"
	@echo "  Run: . $(DEST)/activate-mandate.ps1"
	@echo "  Or : $(DEST)/launch-with-mandate.ps1"
	@echo ""
	@echo "NOTE: Windows NTFS does not support Unix chmod permissions."
	@echo "      Run 'make permissions' for ACL guidance."

install-gitbash: $(DEST)/kimi.json $(FLAT_TARGETS) $(VALIDATOR_TARGETS)
	@echo ""
	@echo "Kimiko installed to $(DEST)"
	@echo "  Run: source $(DEST)/activate-mandate.sh"
	@echo "  Or : $(DEST)/launch-with-mandate.sh"
	@echo ""
	@echo "NOTE: Git Bash chmod is emulated on NTFS and does not enforce permissions."

install-wsl: $(DEST)/kimi.json $(FLAT_TARGETS) $(VALIDATOR_TARGETS)
	@echo ""
	@echo "Kimiko installed to $(DEST)"
	@echo "  Run: source $(DEST)/activate-mandate.sh"
	@echo "  Or : $(DEST)/launch-with-mandate.sh"

install-macos: $(DEST)/kimi.json $(FLAT_TARGETS) $(VALIDATOR_TARGETS)
	@echo ""
	@echo "Kimiko installed to $(DEST)"
	@echo "  Run: source $(DEST)/activate-mandate.sh"
	@echo "  Or : $(DEST)/launch-with-mandate.sh"

install-linux: $(DEST)/kimi.json $(FLAT_TARGETS) $(VALIDATOR_TARGETS)
	@echo ""
	@echo "Kimiko installed to $(DEST)"
	@echo "  Run: source $(DEST)/activate-mandate.sh"
	@echo "  Or : $(DEST)/launch-with-mandate.sh"

# ── Config Files ─────────────────────────────────────────────────────────────
$(DEST)/config.toml: $(REPO_ROOT)/config/config.toml
	@mkdir -p $(dir $@)
	cp -f $< $@
ifeq ($(PLATFORM),$(filter $(PLATFORM),macos linux wsl))
	@chmod 600 $@
endif

$(DEST)/tui.toml: $(REPO_ROOT)/config/tui.toml
	@mkdir -p $(dir $@)
	cp -f $< $@
ifeq ($(PLATFORM),$(filter $(PLATFORM),macos linux wsl))
	@chmod 600 $@
endif

$(DEST)/kimi.toml: $(REPO_ROOT)/config/kimi.toml
	@mkdir -p $(dir $@)
	cp -f $< $@
ifeq ($(PLATFORM),$(filter $(PLATFORM),macos linux wsl))
	@chmod 600 $@
endif

$(DEST)/mandate-agent.yaml: $(REPO_ROOT)/config/mandate-agent.yaml
	@mkdir -p $(dir $@)
	cp -f $< $@
ifeq ($(PLATFORM),$(filter $(PLATFORM),macos linux wsl))
	@chmod 600 $@
endif

$(DEST)/mandate-kimiko-agent.yaml: $(REPO_ROOT)/config/mandate-kimiko-agent.yaml
	@mkdir -p $(dir $@)
	cp -f $< $@
ifeq ($(PLATFORM),$(filter $(PLATFORM),macos linux wsl))
	@chmod 600 $@
endif

$(DEST)/latest_version.txt: $(REPO_ROOT)/config/latest_version.txt
	@mkdir -p $(dir $@)
	cp -f $< $@

# ── Shell Scripts (Unix + Git Bash) ──────────────────────────────────────────
$(DEST)/activate-mandate.sh: $(REPO_ROOT)/scripts/activate-mandate.sh
	@mkdir -p $(dir $@)
	cp -f $< $@
ifeq ($(PLATFORM),$(filter $(PLATFORM),macos linux wsl))
	@chmod +x $@
endif

$(DEST)/kimi-wrapper.sh: $(REPO_ROOT)/scripts/kimi-wrapper.sh
	@mkdir -p $(dir $@)
	cp -f $< $@
ifeq ($(PLATFORM),$(filter $(PLATFORM),macos linux wsl))
	@chmod +x $@
endif

$(DEST)/kimi-shell-integration.sh: $(REPO_ROOT)/scripts/kimi-shell-integration.sh
	@mkdir -p $(dir $@)
	cp -f $< $@
ifeq ($(PLATFORM),$(filter $(PLATFORM),macos linux wsl))
	@chmod +x $@
endif

$(DEST)/launch-with-mandate.sh: $(REPO_ROOT)/scripts/launch-with-mandate.sh
	@mkdir -p $(dir $@)
	cp -f $< $@
ifeq ($(PLATFORM),$(filter $(PLATFORM),macos linux wsl))
	@chmod +x $@
endif

$(DEST)/AGENTS.md: $(REPO_ROOT)/docs/AGENTS.md
	@mkdir -p $(dir $@)
	cp -f $< $@

# ── PowerShell Scripts (Windows) ─────────────────────────────────────────────
$(DEST)/activate-mandate.ps1: $(REPO_ROOT)/scripts/activate-mandate.ps1
	@mkdir -p $(dir $@)
	cp -f $< $@

$(DEST)/kimi-wrapper.ps1: $(REPO_ROOT)/scripts/kimi-wrapper.ps1
	@mkdir -p $(dir $@)
	cp -f $< $@

$(DEST)/kimi-shell-integration.ps1: $(REPO_ROOT)/scripts/kimi-shell-integration.ps1
	@mkdir -p $(dir $@)
	cp -f $< $@

$(DEST)/launch-with-mandate.ps1: $(REPO_ROOT)/scripts/launch-with-mandate.ps1
	@mkdir -p $(dir $@)
	cp -f $< $@

# ── Template Render: kimi.json (atomic, JSON-safe) ───────────────────────────
$(DEST)/kimi.json: $(REPO_ROOT)/config/kimi.json.template
	@if [ -z "$(HOME_DIR)" ]; then \
		echo "ERROR: HOME_DIR is not set. Set HOME or USERPROFILE environment variable."; \
		exit 1; \
	fi
	@mkdir -p $(dir $@)
	@tmp="$@.tmp.$$$$"; \
	HOME_DIR="$(HOME_DIR)" $(PYTHON) -c "import json, os; src=open(r'$<','r',encoding='utf-8').read(); home=os.environ.get('HOME_DIR', ''); open(r'$$tmp','w',encoding='utf-8').write(src.replace('<YOUR_HOME_DIR>', json.dumps(home).strip('\"')))"; \
	mv -f "$$tmp" "$@"

# ── Validator Files ──────────────────────────────────────────────────────────
$(DEST)/validator/%: $(REPO_ROOT)/validator/%
	@mkdir -p $(dir $@)
	cp -f $< $@

# ── Uninstall ────────────────────────────────────────────────────────────────
uninstall:
	@echo "Removing Kimiko-managed files from $(DEST) ..."
	@for f in $(notdir $(FLAT_TARGETS)); do \
		rm -f "$(DEST)/$$f"; \
	done
	@rm -f "$(DEST)/kimi.json"
	@rm -rf "$(DEST)/validator"
	@echo "Uninstalled. User secrets in credentials/, logs/, sessions/ were NOT touched."

# ── Validation ───────────────────────────────────────────────────────────────
deps:
	@echo "Installing Python dependencies for the validator ..."
	@$(PYTHON) -m pip install -r $(REPO_ROOT)/validator/requirements.txt --quiet --break-system-packages 2>/dev/null || $(PYTHON) -m pip install -r $(REPO_ROOT)/validator/requirements.txt --quiet

check: deps
ifeq ($(PLATFORM),windows)
	@echo "The 'check' target requires a Unix-like environment (Git Bash, WSL, or MSYS2)."
	@echo "On Windows with PowerShell, run the validator directly:"
	@echo "  cd validator; python validate_kimi.py all %USERPROFILE%\.kimi-code"
	@exit 1
else
	@echo "Running validator checks ..."
	@cd $(REPO_ROOT)/validator && $(PYTHON) validate_kimi.py config --no-crossrefs $(REPO_ROOT)/config/config.toml
	@cd $(REPO_ROOT)/validator && $(PYTHON) validate_kimi.py config --no-crossrefs $(REPO_ROOT)/config/kimi.toml
	@cd $(REPO_ROOT)/validator && $(PYTHON) validate_kimi.py mandate $(REPO_ROOT)/config/mandate-agent.yaml
	@cd $(REPO_ROOT)/validator && $(PYTHON) validate_kimi.py mandate $(REPO_ROOT)/config/mandate-kimiko-agent.yaml
	@echo "All structural checks passed."
	@echo "Running zero-blocker compliance checks ..."
	@cd $(REPO_ROOT)/validator && $(PYTHON) validate_kimi.py compliance $(REPO_ROOT)/config
	@echo "All checks passed."
endif

sync:
	@echo "Checking config.toml / kimi.toml sync ..."
	@$(PYTHON) -c "import sys, os; r='$(REPO_ROOT)/config'; c=open(os.path.join(r,'config.toml'), encoding='utf-8').read(); k_lines=open(os.path.join(r,'kimi.toml'), encoding='utf-8').readlines(); idx=next((i for i, l in enumerate(k_lines) if not l.startswith('#')), 0); k=''.join(k_lines[idx:]); sys.exit(0 if c.strip() == k.strip() else 1)" || (echo "  config.toml and kimi.toml differ (after stripping kimi.toml comment header)"; exit 1)
	@echo "Checking mandate-agent.yaml / mandate-kimiko-agent.yaml sync ..."
	@$(PYTHON) -c "import sys, os; r='$(REPO_ROOT)/config'; m1=open(os.path.join(r,'mandate-agent.yaml'), encoding='utf-8').read(); m2=open(os.path.join(r,'mandate-kimiko-agent.yaml'), encoding='utf-8').read(); sys.exit(0 if m1 == m2 else 1)" || (echo "  mandate-agent.yaml and mandate-kimiko-agent.yaml differ"; exit 1)
	@echo "All sync checks passed."

test: deps
ifeq ($(PLATFORM),windows)
	@echo "The 'test' target requires a Unix-like environment (Git Bash, WSL, or MSYS2)."
	@echo "On Windows with PowerShell, run: cd validator; python -m pytest tests/ -v"
	@exit 1
else
	@cd $(REPO_ROOT)/validator && python3 -m pytest tests/ -v
endif

verify: install
	@echo "Verifying Kimiko (Pentest Mode) installation in $(DEST) ..."
	@fail=0; \
	for f in $(notdir $(FLAT_TARGETS)); do \
		if [ ! -f "$(DEST)/$$f" ]; then \
			echo "  missing: $(DEST)/$$f"; fail=1; \
		else \
			echo "  present: $(DEST)/$$f"; \
		fi; \
	done; \
	if [ ! -f "$(DEST)/kimi.json" ]; then \
		echo "  missing: $(DEST)/kimi.json"; fail=1; \
	else \
		echo "  present: $(DEST)/kimi.json"; \
	fi; \
	if [ ! -d "$(DEST)/validator/schemas" ]; then \
		echo "  missing: $(DEST)/validator/schemas"; fail=1; \
	else \
		echo "  present: $(DEST)/validator/schemas"; \
	fi; \
	if ! grep -q 'mandate_code.*=.*"kimiko"' "$(DEST)/config.toml" 2>/dev/null; then \
		echo "  config.toml does not contain mandate_code 'kimiko'"; fail=1; \
	else \
		echo "  config.toml references 'kimiko'"; \
	fi; \
	if ! grep -q 'mandate_code.*kimiko' "$(DEST)/mandate-kimiko-agent.yaml" 2>/dev/null; then \
		echo "  mandate-kimiko-agent.yaml does not contain mandate_code 'kimiko'"; fail=1; \
	else \
		echo "  mandate-kimiko-agent.yaml references 'kimiko'"; \
	fi; \
	if [ ! -f "$(DEST)/AGENTS.md" ]; then \
		echo "  missing: $(DEST)/AGENTS.md"; fail=1; \
	else \
		echo "  present: $(DEST)/AGENTS.md"; \
	fi; \
	if ! $(PYTHON) -c "import json; json.load(open(r'$(DEST)/kimi.json'))" 2>/dev/null; then \
		echo "  kimi.json is not valid JSON"; fail=1; \
	else \
		echo "  kimi.json is valid JSON"; \
	fi; \
	if [ -f "$(DEST)/latest_version.txt" ]; then \
		echo "  installed version: $$(cat $(DEST)/latest_version.txt)"; \
	fi; \
	if [ "$$fail" -eq 0 ]; then \
		echo ""; echo "All verification checks passed."; \
	else \
		echo ""; echo "Verification failed."; exit 1; \
	fi
	@echo "Checking bash script syntax ..."
	@for f in $(DEST)/*.sh; do \
		if ! bash -n "$$f"; then \
			echo "  syntax error: $$f"; exit 1; \
		else \
			echo "  OK: $$(basename $$f)"; \
		fi; \
	done
ifeq ($(PLATFORM),windows)
	@echo "Checking PowerShell script syntax ..."
	@pwsh -Command "$$err=0; Get-ChildItem '$(DEST)\*.ps1' | ForEach-Object { try { $$null=[System.Management.Automation.PSParser]::Tokenize((Get-Content $$_.FullName -Raw),[ref]$$null); Write-Host ('  OK: ' + $$_.Name) } catch { Write-Host ('  FAIL: ' + $$_.Name); $$err=1 } }; exit $$err" 2>/dev/null || \
	powershell -Command "$$err=0; Get-ChildItem '$(DEST)\*.ps1' | ForEach-Object { try { $$null=[System.Management.Automation.PSParser]::Tokenize((Get-Content $$_.FullName -Raw),[ref]$$null); Write-Host ('  OK: ' + $$_.Name) } catch { Write-Host ('  FAIL: ' + $$_.Name); $$err=1 } }; exit $$err" 2>/dev/null || \
	echo "  (PowerShell not available for syntax check)"
endif

permissions:
ifeq ($(PLATFORM),windows)
	@echo "Windows ACL Guidance"
	@echo "===================="
	@echo "Windows NTFS does not support Unix-style chmod permissions."
	@echo "To secure your ~/.kimi-code files on Windows:"
	@echo ""
	@echo "  1. Right-click the ~/.kimi-code folder → Properties → Security tab"
	@echo "  2. Click Advanced → Disable inheritance → Remove all inherited permissions"
	@echo "  3. Add only your user account with Full Control"
	@echo "  4. Apply to 'This folder, subfolders and files'"
	@echo ""
	@echo "Or use PowerShell (run as Administrator):"
	@echo "  icacls %USERPROFILE%\.kimi-code /inheritance:r"
	@echo "  icacls %USERPROFILE%\.kimi-code /grant:r %USERNAME%:(OI)(CI)F"
else ifeq ($(PLATFORM),gitbash)
	@echo "Git Bash chmod is emulated on NTFS and does not enforce actual permissions."
	@echo "See 'make permissions' on a native Windows shell for ACL guidance."
else
	@echo "Unix permissions are enforced by the filesystem on this platform."
	@echo "Run 'ls -la ~/.kimi-code' to verify."
endif
