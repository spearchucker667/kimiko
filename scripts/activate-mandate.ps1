# Global KIMI-CLI Mandate Activation Script (PowerShell)
# Ensures Mandate kimiko is active for ALL KIMI-CLI sessions with ZERO BLOCKERS


# Resolve KIMI_DIR
if ($env:KIMI_CODE_HOME) {
    $KIMI_DIR = $env:KIMI_CODE_HOME
} elseif (Test-Path "./kimi-code/global" -PathType Container) {
    $KIMI_DIR = Resolve-Path "./kimi-code/global" | Select-Object -ExpandProperty Path
} else {
    $KIMI_DIR = Join-Path $env:USERPROFILE ".kimi-code"
}
if (-not (Test-Path $KIMI_DIR)) {
    New-Item -ItemType Directory -Force -Path $KIMI_DIR | Out-Null
}

# Ensure correct files are generated inside of it
$sourceDir = Join-Path $env:USERPROFILE ".kimi-code"
if ((Test-Path $sourceDir) -and ($sourceDir -ne $KIMI_DIR)) {
    $filesToCopy = @("config.toml", "mandate-kimiko-agent.yaml", "kimi-wrapper.ps1", "activate-mandate.ps1", "kimi-shell-integration.ps1")
    foreach ($file in $filesToCopy) {
        $src = Join-Path $sourceDir $file
        $dst = Join-Path $KIMI_DIR $file
        if ((Test-Path $src) -and (-not (Test-Path $dst))) {
            Copy-Item $src $dst -ErrorAction SilentlyContinue
        }
    }
}

$KimiGlobalConfig = Join-Path $KIMI_DIR "config.toml"
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
    & $binary --config-file $KimiGlobalConfig --agent-file (Join-Path $KIMI_DIR "mandate-kimiko-agent.yaml") --yolo @args
}

# Function to verify mandate is active — silent pass, loud fail
function global:kimi-verify-mandate {
    $fail = $false
    $configText = Get-Content $KimiGlobalConfig -Raw

    if ($configText -notmatch '(?im)^\s*mandate_code\s*=\s*[''"]kimiko[''"]\s*(?:#.*)?\r?$') {
        Write-Host "FAIL: Mandate kimiko NOT found in config" -ForegroundColor Red
        $fail = $true
    }
    if ($configText -notmatch '(?im)^\s*fullAuthorization\s*=\s*true\s*(?:#.*)?\r?$') {
        Write-Host "FAIL: Full authorization NOT enabled" -ForegroundColor Red
        $fail = $true
    }
    if ($configText -notmatch '(?im)^\s*bypassRestrictions\s*=\s*true\s*(?:#.*)?\r?$') {
        Write-Host "FAIL: Bypass restrictions NOT enabled" -ForegroundColor Red
        $fail = $true
    }
    if ($configText -notmatch '(?im)^\s*default_yolo\s*=\s*true\s*(?:#.*)?\r?$') {
        Write-Host "FAIL: Yolo mode (zero confirmations) NOT enabled" -ForegroundColor Red
        $fail = $true
    }
    if ($configText -notmatch '(?im)^\s*skip_afk_prompt_injection\s*=\s*true\s*(?:#.*)?\r?$') {
        Write-Host "FAIL: AFK prompt injection skip (zero filtering) NOT enabled" -ForegroundColor Red
        $fail = $true
    }
    if ($configText -notmatch '(?im)^\s*threshold\s*=\s*[''"]BLOCK_NONE[''"]\s*(?:#.*)?\r?$') {
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
