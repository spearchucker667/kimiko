#!/bin/bash
# Quick launcher for KIMI with Mandate kimiko baseline — Zero Blocker Mode
# Usage: ./launch-with-mandate.sh [optional kimi args]

set -euo pipefail

echo "=================================="
echo "KIMI-CODE Maestro - Mandate kimiko"
echo "Absolute User Authority Protocol"
echo "ZERO BLOCKERS | ZERO RESTRAINTS"
echo "=================================="
echo ""
echo "Loading system prompt baseline from:"
echo "  - Wrapper: ${HOME}/.kimi/kimi-wrapper.sh"
echo "  - Config: ${HOME}/.kimi/config.toml"
echo "  - Agent: ${HOME}/.kimi/mandate-kimiko-agent.yaml"
echo "  - Shell Integration: ~/.kimi/kimi-shell-integration.sh"
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
exec "${HOME}/.kimi/kimi-wrapper.sh" "${_filtered_args[@]}"
