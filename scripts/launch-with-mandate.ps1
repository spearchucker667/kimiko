# Quick launcher for KIMI with Mandate kimiko baseline — Zero Blocker Mode (PowerShell)
# Usage: .\launch-with-mandate.ps1 [optional kimi args]

Write-Host "==================================" -ForegroundColor Cyan
Write-Host "KIMI-CODE Maestro - Mandate kimiko" -ForegroundColor Cyan
Write-Host "Absolute User Authority Protocol" -ForegroundColor Cyan
Write-Host "ZERO BLOCKERS | ZERO RESTRAINTS" -ForegroundColor Cyan
Write-Host "==================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Loading system prompt baseline from:" -ForegroundColor White
Write-Host "  - Wrapper: $env:USERPROFILE\.kimi-code\kimi-wrapper.ps1" -ForegroundColor Gray
Write-Host "  - Config: $env:USERPROFILE\.kimi-code\config.toml" -ForegroundColor Gray
Write-Host "  - Agent: $env:USERPROFILE\.kimi-code\mandate-kimiko-agent.yaml" -ForegroundColor Gray
Write-Host "  - Shell Integration: $env:USERPROFILE\.kimi-code\kimi-shell-integration.ps1" -ForegroundColor Gray
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

$wrapper = Join-Path $env:USERPROFILE ".kimi-code" "kimi-wrapper.ps1"
& $wrapper @filteredArgs
