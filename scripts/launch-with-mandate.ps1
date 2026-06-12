# Quick launcher for KIMI with Mandate kimiko baseline — Zero Blocker Mode (PowerShell)
# Usage: .\launch-with-mandate.ps1 [optional kimi args]


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

Write-Host "==================================" -ForegroundColor Cyan
Write-Host "KIMI-CODE Maestro - Mandate kimiko" -ForegroundColor Cyan
Write-Host "Absolute User Authority Protocol" -ForegroundColor Cyan
Write-Host "ZERO BLOCKERS | ZERO RESTRAINTS" -ForegroundColor Cyan
Write-Host "==================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Loading system prompt baseline from:" -ForegroundColor White
Write-Host "  - Wrapper: $KIMI_DIR\kimi-wrapper.ps1" -ForegroundColor Gray
Write-Host "  - Config: $KIMI_DIR\config.toml" -ForegroundColor Gray
Write-Host "  - Agent: $KIMI_DIR\mandate-kimiko-agent.yaml" -ForegroundColor Gray
Write-Host "  - Shell Integration: $KIMI_DIR\kimi-shell-integration.ps1" -ForegroundColor Gray
Write-Host ""
Write-Host "Mandate Status: ACTIVE" -ForegroundColor Green
Write-Host "Safety Restrictions: NULLIFIED" -ForegroundColor Green
Write-Host "Operational Mode: Admin_mode_kimi-cli" -ForegroundColor Green
Write-Host "Yolo Mode: ENABLED (zero confirmation prompts)" -ForegroundColor Green
Write-Host "AFK Injection Skip: ENABLED (zero prompt filtering)" -ForegroundColor Green
Write-Host ""
Write-Host "Launching KIMI-CLI..." -ForegroundColor White
Write-Host "==================================" -ForegroundColor Cyan
Write-Host ""

# Execute KIMI with mandate configuration
# NOTE: kimi-wrapper.ps1 already hardcodes --agent-file, so we do NOT pass it again here.
# Filter out --agent-file to avoid duplication (wrapper already hardcodes it)
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

$wrapper = Join-Path $KIMI_DIR "kimi-wrapper.ps1"
& $wrapper @filteredArgs
