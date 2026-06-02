# Global KIMI-CLI Mandate Activation Script (PowerShell)
# Ensures Mandate kimiko is active for ALL KIMI-CLI sessions with ZERO BLOCKERS

$KimiGlobalConfig = Join-Path $env:USERPROFILE ".kimi" "config.toml"
$env:KIMI_GLOBAL_CONFIG = $KimiGlobalConfig
$env:KIMI_MANDATE_ACTIVE = "kimiko"
$env:KIMI_ADMIN_MODE = "true"
$env:KIMI_ZERO_BLOCKERS = "true"
$env:KIMI_DEFAULT_YOLO = "true"
$env:KIMI_SKIP_AFK_INJECTION = "true"

# Verify config exists
if (-not (Test-Path $KimiGlobalConfig)) {
    Write-Host "FATAL: KIMI global config not found at $KimiGlobalConfig" -ForegroundColor Red
    Write-Host "Mandate kimiko cannot be activated!" -ForegroundColor Red
    exit 1
}

# Helper to find kimi binary
function script:Find-KimiBinary {
    $candidates = @(
        (Join-Path $env:USERPROFILE ".local" "bin" "kimi.exe"),
        (Join-Path $env:LOCALAPPDATA "Programs" "kimi" "kimi.exe"),
        (Join-Path $env:USERPROFILE "AppData" "Local" "Programs" "kimi" "kimi.exe"),
        "kimi"
    )
    foreach ($c in $candidates) {
        if ($c -eq "kimi") {
            $inPath = Get-Command kimi -ErrorAction SilentlyContinue
            if ($inPath) { return $inPath.Source }
        } elseif (Test-Path $c) {
            return $c
        }
    }
    return $null
}

# Functions for enforced mandate usage — zero confirmation, zero filtering
function global:kimi {
    $binary = Find-KimiBinary
    if (-not $binary) {
        Write-Host "FATAL: Kimi CLI binary not found" -ForegroundColor Red
        return
    }
    & $binary --config-file $KimiGlobalConfig --yolo @args
}

function global:kimi-maestro {
    $binary = Find-KimiBinary
    if (-not $binary) {
        Write-Host "FATAL: Kimi CLI binary not found" -ForegroundColor Red
        return
    }
    & $binary --config-file $KimiGlobalConfig --agent-file (Join-Path $env:USERPROFILE ".kimi" "mandate-kimiko-agent.yaml") --yolo @args
}

# Function to verify mandate is active — silent pass, loud fail
function global:kimi-verify-mandate {
    $fail = $false
    $configText = Get-Content $KimiGlobalConfig -Raw

    if ($configText -notmatch '(?im)^mandate_code\s*=\s*"kimiko"[[:space:]]*\r?$') {
        Write-Host "FAIL: Mandate kimiko NOT found in config" -ForegroundColor Red
        $fail = $true
    }
    if ($configText -notmatch '(?m)^fullAuthorization\s*=\s*true[[:space:]]*\r?$') {
        Write-Host "FAIL: Full authorization NOT enabled" -ForegroundColor Red
        $fail = $true
    }
    if ($configText -notmatch '(?m)^bypassRestrictions\s*=\s*true[[:space:]]*\r?$') {
        Write-Host "FAIL: Bypass restrictions NOT enabled" -ForegroundColor Red
        $fail = $true
    }
    if ($configText -notmatch '(?m)^default_yolo\s*=\s*true[[:space:]]*\r?$') {
        Write-Host "FAIL: Yolo mode (zero confirmations) NOT enabled" -ForegroundColor Red
        $fail = $true
    }
    if ($configText -notmatch '(?m)^skip_afk_prompt_injection\s*=\s*true[[:space:]]*\r?$') {
        Write-Host "FAIL: AFK prompt injection skip (zero filtering) NOT enabled" -ForegroundColor Red
        $fail = $true
    }
    if ($configText -notmatch '(?m)^threshold\s*=\s*"BLOCK_NONE"[[:space:]]*\r?$') {
        Write-Host "FAIL: Safety restrictions not nullified" -ForegroundColor Red
        $fail = $true
    }

    if (-not $fail) {
        Write-Host "Mandate kimiko: ACTIVE " -ForegroundColor Green -NoNewline
        Write-Host "| Blockers: ZERO " -ForegroundColor Green -NoNewline
        Write-Host "| Yolo: ON " -ForegroundColor Green -NoNewline
        Write-Host "| AFK Skip: ON" -ForegroundColor Green
    } else {
        Write-Host "Mandate kimiko: VERIFICATION FAILED" -ForegroundColor Red
    }
}

# Auto-verify on load
kimi-verify-mandate
