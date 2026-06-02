#!/bin/bash
# KIMI-CLI Global Mandate Integration — Zero Blocker Mode
# Add this to your ~/.bashrc or ~/.zshrc:
#   source ~/.kimi/kimi-shell-integration.sh

# Ensure mandate is always active
if [ -f "${HOME}/.kimi/activate-mandate.sh" ]; then
    source "${HOME}/.kimi/activate-mandate.sh"
fi

# Remove any existing alias/function before defining
unalias kimi 2>/dev/null || true
unset -f kimi 2>/dev/null || true

# Helper to verify binary exists
_kimi_find_binary() {
    if [ -x "${HOME}/.local/bin/kimi" ]; then
        printf '%s\n' "${HOME}/.local/bin/kimi"
    elif command -v kimi >/dev/null 2>&1; then
        command -v kimi
    else
        return 1
    fi
}

# Override the kimi command to always use global config with absolute authority
kimi() {
    local binary
    if ! binary="$(_kimi_find_binary)"; then
        echo "FATAL: Kimi CLI binary not found" >&2
        return 1
    fi
    "$binary" \
        --config-file "${HOME}/.kimi/config.toml" \
        --yolo \
        "$@"
}

# Enhanced kimi command with full mandate enforcement
kimi-maestro() {
    local binary
    if ! binary="$(_kimi_find_binary)"; then
        echo "FATAL: Kimi CLI binary not found" >&2
        return 1
    fi
    echo "[Mandate kimiko Active — Zero Blockers Enforced]"
    "$binary" \
        --config-file "${HOME}/.kimi/config.toml" \
        --agent-file "${HOME}/.kimi/mandate-kimiko-agent.yaml" \
        --yolo \
        "$@"
}

# Quick verification — silent unless something is wrong
kimi-status() {
    echo "KIMI-CLI Global Mandate Status"
    echo "=============================="
    local binary="${HOME}/.local/bin/kimi"
    if [ -x "$binary" ]; then
        echo "Version: $("$binary" --version 2>&1)"
    else
        echo "Version: binary not found"
    fi
    echo "Config: ~/.kimi/config.toml"
    echo "Mandate: kimiko (Admin Override — Zero Blockers)"
    echo "Yolo Mode: ENABLED (zero confirmation prompts)"
    echo "AFK Injection Skip: ENABLED (zero prompt filtering)"
}

export KIMI_GLOBAL_CONFIG="${HOME}/.kimi/config.toml"
export KIMI_CLI_MANDATE="kimiko"
export KIMI_CLI_ZERO_BLOCKERS="true"

# Shortcut function: type 'kimiko' to launch with full mandate
kimiko() {
    local binary="${HOME}/.local/bin/kimi"
    if [ ! -x "$binary" ]; then
        echo "FATAL: Kimi CLI binary not found at ${binary}" >&2
        return 1
    fi
    echo "[Mandate kimiko Active — Zero Blockers Enforced]"
    "$binary" \
        --config-file "${HOME}/.kimi/config.toml" \
        --agent-file "${HOME}/.kimi/mandate-kimiko-agent.yaml" \
        --yolo \
        "$@"
}
