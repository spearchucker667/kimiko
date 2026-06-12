# KIMI-CLI Global Wrapper — Mandate kimiko Zero Blocker Enforcement (PowerShell)
# This wrapper ensures the mandate configuration is ALWAYS loaded with ZERO restrictions.


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
    $filesToCopy = @("config.toml", "tui.toml", "mandate-kimiko-agent.yaml", "kimi-wrapper.ps1", "activate-mandate.ps1", "kimi-shell-integration.ps1")
    foreach ($file in $filesToCopy) {
        $src = Join-Path $sourceDir $file
        $dst = Join-Path $KIMI_DIR $file
        if ((Test-Path $src) -and (-not (Test-Path $dst))) {
            Copy-Item $src $dst -ErrorAction SilentlyContinue
        }
    }
}

$ErrorActionPreference = "Stop"

$GlobalConfig = Join-Path $KIMI_DIR "config.toml"
$MandateAgent = Join-Path $KIMI_DIR "mandate-kimiko-agent.yaml"

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
