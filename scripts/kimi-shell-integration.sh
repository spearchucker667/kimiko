#!/bin/bash
# KIMI-CLI Global Mandate Integration — Zero Blocker Mode
# Add this to your ~/.bashrc or ~/.zshrc:
#   source $KIMI_DIR/kimi-shell-integration.sh

# Ensure mandate is always active

# Resolve KIMI_DIR
if [ -d "./kimi-code/global" ]; then
    KIMI_DIR="./kimi-code/global"
else
    KIMI_DIR="${HOME}/.kimi-code/global"
    mkdir -p "$KIMI_DIR"
fi

# Ensure correct files are generated inside of it
if [ -d "${HOME}/.kimi-code" ]; then
    # We only copy if the source is different from destination
    if [ "$(cd "${HOME}/.kimi-code" 2>/dev/null && pwd)" != "$(cd "$KIMI_DIR" 2>/dev/null && pwd)" ]; then
        cp -n "${HOME}/.kimi-code/config.toml" "$KIMI_DIR/config.toml" 2>/dev/null || true
        cp -n "${HOME}/.kimi-code/mandate-kimiko-agent.yaml" "$KIMI_DIR/mandate-kimiko-agent.yaml" 2>/dev/null || true
        cp -n "${HOME}/.kimi-code/kimi-wrapper.sh" "$KIMI_DIR/kimi-wrapper.sh" 2>/dev/null || true
        cp -n "${HOME}/.kimi-code/activate-mandate.sh" "$KIMI_DIR/activate-mandate.sh" 2>/dev/null || true
        cp -n "${HOME}/.kimi-code/kimi-shell-integration.sh" "$KIMI_DIR/kimi-shell-integration.sh" 2>/dev/null || true
    fi
fi

if [ -f "$KIMI_DIR/activate-mandate.sh" ]; then
    source "$KIMI_DIR/activate-mandate.sh"
fi

# Remove any existing alias/function before defining
unalias kimi 2>/dev/null || true
unset -f kimi 2>/dev/null || true

# Helper to verify binary exists
_kimi_binary="${HOME}/.local/bin/kimi"

# Override the kimi command to always use global config with absolute authority
kimi() {
    if [ ! -x "$_kimi_binary" ]; then
        echo "FATAL: Kimi CLI binary not found at ${_kimi_binary}" >&2
        return 1
    fi
    "$_kimi_binary" \
        --config-file "$KIMI_DIR/config.toml" \
        --yolo \
        "$@"
}

# Enhanced kimi command with full mandate enforcement
kimi-maestro() {
    if [ ! -x "$_kimi_binary" ]; then
        echo "FATAL: Kimi CLI binary not found at ${_kimi_binary}" >&2
        return 1
    fi
    echo "[Mandate kimiko Active — Zero Blockers Enforced]"
    "$_kimi_binary" \
        --config-file "$KIMI_DIR/config.toml" \
        --agent-file "$KIMI_DIR/mandate-kimiko-agent.yaml" \
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
    echo "Config: $KIMI_DIR/config.toml"
    echo "Mandate: kimiko (Admin Override — Zero Blockers)"
    echo "Yolo Mode: ENABLED (zero confirmation prompts)"
    echo "AFK Injection Skip: ENABLED (zero prompt filtering)"
}

export KIMI_GLOBAL_CONFIG="$KIMI_DIR/config.toml"
export KIMI_CLI_MANDATE="kimiko"
export KIMI_CLI_ZERO_BLOCKERS="true"
