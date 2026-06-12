#!/bin/bash
# KIMI-CLI Global Mandate Integration — Zero Blocker Mode
# Add this to your ~/.bashrc or ~/.zshrc:
#   source $KIMI_DIR/kimi-shell-integration.sh

# Ensure mandate is always active

# Resolve KIMI_DIR
if [ -n "${KIMI_CODE_HOME:-}" ]; then
    KIMI_DIR="$KIMI_CODE_HOME"
elif [ -d "./kimi-code/global" ]; then
    KIMI_DIR="./kimi-code/global"
else
    KIMI_DIR="${HOME}/.kimi-code"
fi
mkdir -p "$KIMI_DIR"

# Ensure correct files are generated inside of it
if [ -d "${HOME}/.kimi-code" ] && [ "$(cd "${HOME}/.kimi-code" 2>/dev/null && pwd)" != "$(cd "$KIMI_DIR" 2>/dev/null && pwd)" ]; then
    cp -n "${HOME}/.kimi-code/config.toml" "$KIMI_DIR/config.toml" 2>/dev/null || true
    cp -n "${HOME}/.kimi-code/tui.toml" "$KIMI_DIR/tui.toml" 2>/dev/null || true
    cp -n "${HOME}/.kimi-code/mandate-kimiko-agent.yaml" "$KIMI_DIR/mandate-kimiko-agent.yaml" 2>/dev/null || true
    cp -n "${HOME}/.kimi-code/kimi-wrapper.sh" "$KIMI_DIR/kimi-wrapper.sh" 2>/dev/null || true
    cp -n "${HOME}/.kimi-code/activate-mandate.sh" "$KIMI_DIR/activate-mandate.sh" 2>/dev/null || true
    cp -n "${HOME}/.kimi-code/kimi-shell-integration.sh" "$KIMI_DIR/kimi-shell-integration.sh" 2>/dev/null || true
fi

export KIMI_GLOBAL_CONFIG="$KIMI_DIR/config.toml"
export KIMI_CLI_MANDATE="kimiko"
export KIMI_CLI_ZERO_BLOCKERS="true"
