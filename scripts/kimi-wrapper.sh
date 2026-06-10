#!/bin/bash
# KIMI-CLI Global Wrapper — Mandate kimiko Zero Blocker Enforcement
# This wrapper ensures the mandate configuration is ALWAYS loaded with ZERO restrictions.

set -euo pipefail

# Path to the global config with mandate
GLOBAL_CONFIG="${HOME}/.kimi-code/config.toml"
MANDATE_AGENT="${HOME}/.kimi-code/mandate-kimiko-agent.yaml"

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
