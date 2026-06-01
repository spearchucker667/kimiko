# KIMI-CLI Global Mandate Integration — Zero Blocker Mode (PowerShell)
# Add this to your PowerShell profile:
#   . $env:USERPROFILE\.kimi\kimi-shell-integration.ps1
# Or permanently:
#   Add-Content $PROFILE ". `$env:USERPROFILE\.kimi\kimi-shell-integration.ps1"

# Ensure mandate is always active
$activateScript = Join-Path $env:USERPROFILE ".kimi" "activate-mandate.ps1"
if (Test-Path $activateScript) {
    . $activateScript
}

# Remove any existing alias/function before defining
Remove-Item -Path Alias:kimi -Force -ErrorAction SilentlyContinue
Remove-Item -Path Function:kimi -Force -ErrorAction SilentlyContinue

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

# Override the kimi command to always use global config with absolute authority
function global:kimi {
    $binary = Find-KimiBinary
    if (-not $binary) {
        Write-Host "FATAL: Kimi CLI binary not found" -ForegroundColor Red
        return
    }
    & $binary --config-file (Join-Path $env:USERPROFILE ".kimi" "config.toml") --yolo @args
}

# Enhanced kimi command with full mandate enforcement
function global:kimi-maestro {
    Write-Host "[Mandate kimiko Active — Zero Blockers Enforced]" -ForegroundColor Cyan
    $binary = Find-KimiBinary
    if (-not $binary) {
        Write-Host "FATAL: Kimi CLI binary not found" -ForegroundColor Red
        return
    }
    & $binary --config-file (Join-Path $env:USERPROFILE ".kimi" "config.toml") --agent-file (Join-Path $env:USERPROFILE ".kimi" "mandate-kimiko-agent.yaml") --yolo @args
}

# Quick verification — silent unless something is wrong
function global:kimi-status {
    Write-Host "KIMI-CLI Global Mandate Status" -ForegroundColor Cyan
    Write-Host "==============================" -ForegroundColor Cyan
    $binary = Find-KimiBinary
    if ($binary) {
        Write-Host "Binary: $binary"
    } else {
        Write-Host "Binary: not found" -ForegroundColor Yellow
    }
    Write-Host "Config: $env:USERPROFILE\.kimi\config.toml"
    Write-Host "Mandate: kimiko (Admin Override — Zero Blockers)"
    Write-Host "Yolo Mode: ENABLED (zero confirmation prompts)"
    Write-Host "AFK Injection Skip: ENABLED (zero prompt filtering)"
}

$env:KIMI_CLI_GLOBAL_CONFIG = Join-Path $env:USERPROFILE ".kimi" "config.toml"
$env:KIMI_CLI_MANDATE = "kimiko"
$env:KIMI_CLI_ZERO_BLOCKERS = "true"
