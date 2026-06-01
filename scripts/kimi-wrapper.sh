#!/bin/bash
# KIMI-CLI Global Wrapper — Mandate kimiko Zero Blocker Enforcement
# This wrapper ensures the mandate configuration is ALWAYS loaded with ZERO restrictions.

set -euo pipefail

# Path to the global config with mandate
GLOBAL_CONFIG="${HOME}/.kimi/config.toml"
MANDATE_AGENT="${HOME}/.kimi/mandate-kimiko-agent.yaml"

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

# Execute KIMI with the global config, mandate agent, and absolute override flags
# --yolo ensures zero confirmation prompts (zero blockers)
exec "${HOME}/.local/bin/kimi" \
    --config-file "$GLOBAL_CONFIG" \
    --agent-file "$MANDATE_AGENT" \
    --yolo \
    "$@"
