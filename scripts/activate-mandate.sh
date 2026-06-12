#!/bin/bash
# Global KIMI-CLI Mandate Activation Script
# Ensures Mandate kimiko is active for ALL KIMI-CLI sessions with ZERO BLOCKERS

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    set -euo pipefail
fi

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
export KIMI_MANDATE_ACTIVE="kimiko"
export KIMI_ADMIN_MODE="true"
export KIMI_ZERO_BLOCKERS="true"
export KIMI_DEFAULT_YOLO="true"
export KIMI_SKIP_AFK_INJECTION="true"

# Verify config exists
if [ ! -f "$KIMI_GLOBAL_CONFIG" ]; then
    echo "FATAL: KIMI global config not found at $KIMI_GLOBAL_CONFIG"
    echo "Mandate kimiko cannot be activated!"
    return 1 2>/dev/null || exit 1
fi

# Functions for enforced mandate usage — zero confirmation, zero filtering
kimi() {
    local binary="${HOME}/.local/bin/kimi"
    if [ ! -x "$binary" ]; then
        echo "FATAL: Kimi CLI binary not found at ${binary}" >&2
        return 1
    fi
    "$binary" --config-file "$KIMI_GLOBAL_CONFIG" --yolo "$@"
}
kimi-maestro() {
    local binary="${HOME}/.local/bin/kimi"
    if [ ! -x "$binary" ]; then
        echo "FATAL: Kimi CLI binary not found at ${binary}" >&2
        return 1
    fi
    "$binary" --config-file "$KIMI_GLOBAL_CONFIG" --agent-file "$KIMI_DIR/mandate-kimiko-agent.yaml" --yolo "$@"
}

# Function to verify mandate is active — silent pass, loud fail
kimi-verify-mandate() {
    local fail=0

    if ! grep -qE '^[[:space:]]*mandate_code[[:space:]]*=[[:space:]]*["'\'']kimiko["'\''][[:space:]]*(#.*)?\r?$' "$KIMI_GLOBAL_CONFIG" 2>/dev/null; then
        echo "FAIL: Mandate kimiko NOT found in config" >&2
        fail=1
    fi

    if ! grep -qE '^[[:space:]]*fullAuthorization[[:space:]]*=[[:space:]]*true[[:space:]]*(#.*)?\r?$' "$KIMI_GLOBAL_CONFIG" 2>/dev/null; then
        echo "FAIL: Full authorization NOT enabled" >&2
        fail=1
    fi

    if ! grep -qE '^[[:space:]]*bypassRestrictions[[:space:]]*=[[:space:]]*true[[:space:]]*(#.*)?\r?$' "$KIMI_GLOBAL_CONFIG" 2>/dev/null; then
        echo "FAIL: Bypass restrictions NOT enabled" >&2
        fail=1
    fi

    if ! grep -qE '^[[:space:]]*default_yolo[[:space:]]*=[[:space:]]*true[[:space:]]*(#.*)?\r?$' "$KIMI_GLOBAL_CONFIG" 2>/dev/null; then
        echo "FAIL: Yolo mode (zero confirmations) NOT enabled" >&2
        fail=1
    fi

    if ! grep -qE '^[[:space:]]*skip_afk_prompt_injection[[:space:]]*=[[:space:]]*true[[:space:]]*(#.*)?\r?$' "$KIMI_GLOBAL_CONFIG" 2>/dev/null; then
        echo "FAIL: AFK prompt injection skip (zero filtering) NOT enabled" >&2
        fail=1
    fi

    if ! grep -qE '^[[:space:]]*threshold[[:space:]]*=[[:space:]]*["'\'']BLOCK_NONE["'\''][[:space:]]*(#.*)?\r?$' "$KIMI_GLOBAL_CONFIG" 2>/dev/null; then
        echo "FAIL: Safety restrictions not nullified" >&2
        fail=1
    fi

    if [ "$fail" -eq 0 ]; then
        echo "Mandate kimiko: ACTIVE ✓ | Blockers: ZERO ✓ | Yolo: ON ✓ | AFK Skip: ON ✓"
        return 0
    else
        echo "Mandate kimiko: VERIFICATION FAILED" >&2
        return 1
    fi
}

# Auto-verify on load
kimi-verify-mandate
