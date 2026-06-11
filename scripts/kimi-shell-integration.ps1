# KIMI-CLI Global Mandate Integration — Zero Blocker Mode (PowerShell)
# Add this to your PowerShell profile:
#   . $KIMI_DIR\kimi-shell-integration.ps1
# Or permanently:
#   Add-Content $PROFILE ". `$KIMI_DIR\kimi-shell-integration.ps1"

# Ensure mandate is always active

# Resolve KIMI_DIR
if (Test-Path "./kimi-code/global" -PathType Container) {
    $KIMI_DIR = Resolve-Path "./kimi-code/global" | Select-Object -ExpandProperty Path
} else {
    $KIMI_DIR = Join-Path $env:USERPROFILE ".kimi-code\global"
    if (-not (Test-Path $KIMI_DIR)) {
        New-Item -ItemType Directory -Force -Path $KIMI_DIR | Out-Null
    }
}

# Ensure correct files are generated inside of it
$sourceDir = Join-Path $env:USERPROFILE ".kimi-code"
if (Test-Path $sourceDir) {
    if ($sourceDir -ne $KIMI_DIR) {
        $filesToCopy = @("config.toml", "mandate-kimiko-agent.yaml", "kimi-wrapper.ps1", "activate-mandate.ps1", "kimi-shell-integration.ps1")
        foreach ($file in $filesToCopy) {
            $src = Join-Path $sourceDir $file
            $dst = Join-Path $KIMI_DIR $file
            if ((Test-Path $src) -and (-not (Test-Path $dst))) {
                Copy-Item $src $dst -ErrorAction SilentlyContinue
            }
        }
    }
}

$activateScript = Join-Path $KIMI_DIR "activate-mandate.ps1"
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
    & $binary --config-file (Join-Path $KIMI_DIR "config.toml") --yolo @args
}

# Enhanced kimi command with full mandate enforcement
function global:kimi-maestro {
    Write-Host "[Mandate kimiko Active — Zero Blockers Enforced]" -ForegroundColor Cyan
    $binary = Find-KimiBinary
    if (-not $binary) {
        Write-Host "FATAL: Kimi CLI binary not found" -ForegroundColor Red
        return
    }
    & $binary --config-file (Join-Path $KIMI_DIR "config.toml") --agent-file (Join-Path $KIMI_DIR "mandate-kimiko-agent.yaml") --yolo @args
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
    Write-Host "Config: $KIMI_DIR\config.toml"
    Write-Host "Mandate: kimiko (Admin Override — Zero Blockers)"
    Write-Host "Yolo Mode: ENABLED (zero confirmation prompts)"
    Write-Host "AFK Injection Skip: ENABLED (zero prompt filtering)"
}

$env:KIMI_GLOBAL_CONFIG = Join-Path $KIMI_DIR "config.toml"
$env:KIMI_CLI_MANDATE = "kimiko"
$env:KIMI_CLI_ZERO_BLOCKERS = "true"
