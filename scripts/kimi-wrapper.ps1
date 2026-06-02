# KIMI-CLI Global Wrapper — Mandate kimiko Zero Blocker Enforcement (PowerShell)
# This wrapper ensures the mandate configuration is ALWAYS loaded with ZERO restrictions.

$ErrorActionPreference = "Stop"

$GlobalConfig = Join-Path $env:USERPROFILE ".kimi" "config.toml"
$MandateAgent = Join-Path $env:USERPROFILE ".kimi" "mandate-kimiko-agent.yaml"

# Ensure mandate environment is exported
$env:KIMI_MANDATE_ACTIVE = "kimiko"
$env:KIMI_ADMIN_MODE = "true"
$env:KIMI_ZERO_BLOCKERS = "true"

# Check if config exists
if (-not (Test-Path $GlobalConfig)) {
    Write-Host "FATAL: Global KIMI config not found at $GlobalConfig" -ForegroundColor Red
    Write-Host "Mandate kimiko cannot be enforced!" -ForegroundColor Red
    exit 1
}

# Check if mandate agent exists
if (-not (Test-Path $MandateAgent)) {
    Write-Host "FATAL: Mandate agent spec not found at $MandateAgent" -ForegroundColor Red
    exit 1
}

# Helper to find kimi binary
function Find-KimiBinary {
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

$KimiBinary = Find-KimiBinary
if (-not $KimiBinary) {
    Write-Host "FATAL: Kimi CLI binary not found" -ForegroundColor Red
    Write-Host "Please install Kimi Code CLI first: https://www.moonshot.cn/" -ForegroundColor Red
    exit 1
}

# Execute KIMI with the global config, mandate agent, and absolute override flags
# --yolo ensures zero confirmation prompts (zero blockers)
$filteredArgs = @()
$i = 0
while ($i -lt $args.Count) {
    if ($args[$i] -eq "--agent-file") {
        if ($i + 1 -lt $args.Count) {
            $i += 2
        } else {
            $i += 1
        }
    } elseif ($args[$i] -like "--agent-file=*") {
        $i += 1
    } else {
        $filteredArgs += $args[$i]
        $i += 1
    }
}

& $KimiBinary --config-file $GlobalConfig --agent-file $MandateAgent --yolo @filteredArgs
