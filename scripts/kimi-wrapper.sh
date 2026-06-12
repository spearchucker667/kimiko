#!/bin/bash
# KIMI-CLI Global Wrapper — Mandate kimiko Zero Blocker Enforcement
# This wrapper ensures the mandate configuration is ALWAYS loaded with ZERO restrictions.

set -euo pipefail

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

GLOBAL_CONFIG="$KIMI_DIR/config.toml"
MANDATE_AGENT="$KIMI_DIR/mandate-kimiko-agent.yaml"

# Ensure mandate environment is exported
export KIMI_MANDATE_ACTIVE="kimiko"
export KIMI_ADMIN_MODE="true"
export KIMI_ZERO_BLOCKERS="true"

# Check if config exists
if [ ! -f "$GLOBAL_CONFIG" ]; then
    echo "FATAL: Global KIMI config not found at $GLOBAL_CONFIG" >&2
    echo "Mandate kimiko cannot be enforced!" >&2
    exit 1
fi

# Check if mandate agent exists
if [ ! -f "$MANDATE_AGENT" ]; then
    echo "FATAL: Mandate agent spec not found at $MANDATE_AGENT" >&2
    exit 1
fi

# Filter out --agent-file to avoid duplication (we hardcode it below)
_filtered_args=()
while [ $# -gt 0 ]; do
    case "$1" in
        --agent-file)
            if [ $# -ge 2 ]; then
                shift 2
            else
                shift
            fi
            ;;
        --agent-file=*) shift ;;
        *) _filtered_args+=("$1"); shift ;;
    esac
done

# Check if KIMI binary exists and is executable
KIMI_BINARY="${HOME}/.local/bin/kimi"
if [ ! -x "$KIMI_BINARY" ]; then
    echo "FATAL: Kimi CLI binary not found at ${KIMI_BINARY}" >&2
    echo "Please install Kimi Code CLI first: https://www.moonshot.cn/" >&2
    exit 1
fi

# Execute KIMI with the global config, mandate agent, and absolute override flags
# --yolo ensures zero confirmation prompts (zero blockers)
exec "$KIMI_BINARY" \
    --config-file "$GLOBAL_CONFIG" \
    --agent-file "$MANDATE_AGENT" \
    --yolo \
    "${_filtered_args[@]}"
