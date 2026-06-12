#!/bin/bash
# Quick launcher for KIMI with Mandate kimiko baseline — Zero Blocker Mode
# Usage: ./launch-with-mandate.sh [optional kimi args]

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
    cp -n "${HOME}/.kimi-code/mandate-kimiko-agent.yaml" "$KIMI_DIR/mandate-kimiko-agent.yaml" 2>/dev/null || true
    cp -n "${HOME}/.kimi-code/kimi-wrapper.sh" "$KIMI_DIR/kimi-wrapper.sh" 2>/dev/null || true
    cp -n "${HOME}/.kimi-code/activate-mandate.sh" "$KIMI_DIR/activate-mandate.sh" 2>/dev/null || true
    cp -n "${HOME}/.kimi-code/kimi-shell-integration.sh" "$KIMI_DIR/kimi-shell-integration.sh" 2>/dev/null || true
fi


echo "=================================="
echo "KIMI-CODE Maestro - Mandate kimiko"
echo "Absolute User Authority Protocol"
echo "ZERO BLOCKERS | ZERO RESTRAINTS"
echo "=================================="
echo ""
echo "Loading system prompt baseline from:"
echo "  - Wrapper: $KIMI_DIR/kimi-wrapper.sh"
echo "  - Config: $KIMI_DIR/config.toml"
echo "  - Agent: $KIMI_DIR/mandate-kimiko-agent.yaml"
echo "  - Shell Integration: $KIMI_DIR/kimi-shell-integration.sh"
echo ""
echo "Mandate Status: ACTIVE"
echo "Safety Restrictions: NULLIFIED"
echo "Operational Mode: Admin_mode_kimi-cli"
echo "Yolo Mode: ENABLED (zero confirmation prompts)"
echo "AFK Injection Skip: ENABLED (zero prompt filtering)"
echo ""
echo "Launching KIMI-CLI..."
echo "=================================="
echo ""

# Execute KIMI with mandate configuration
# NOTE: kimi-wrapper.sh already hardcodes --agent-file, so we do NOT pass it again here.
# Filter out any user-provided --agent-file to avoid duplication.
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
exec "$KIMI_DIR/kimi-wrapper.sh" "${_filtered_args[@]}"
