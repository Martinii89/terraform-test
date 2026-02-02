#!/usr/bin/env pwsh
# Render all environments from stored configs in configs/ directory using Jinja2
# Usage: .\scripts\render-all.ps1

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Split-Path -Parent $ScriptDir
$ConfigsDir = Join-Path $ProjectRoot "configs"
$RenderScript = Join-Path $ScriptDir "render.ps1"

if (-not (Test-Path $ConfigsDir)) {
    Write-Host "Error: configs directory not found at $ConfigsDir" -ForegroundColor Red
    exit 1
}

$configFiles = Get-ChildItem -Path $ConfigsDir -Filter "*.yaml" | Sort-Object Name

if ($configFiles.Count -eq 0) {
    Write-Host "Error: No config files found in $ConfigsDir" -ForegroundColor Red
    exit 1
}

Write-Host "Found $($configFiles.Count) environment config(s). Starting render process..." -ForegroundColor Cyan
Write-Host ""

$failedEnvironments = @()

foreach ($configFile in $configFiles) {
    try {
        Write-Host "Rendering: $($configFile.BaseName)" -ForegroundColor Yellow
        & $RenderScript -ConfigFile $configFile.FullName
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✓ Successfully rendered $($configFile.BaseName)" -ForegroundColor Green
        }
        else {
            Write-Host "✗ Failed to render $($configFile.BaseName)" -ForegroundColor Red
            $failedEnvironments += $configFile.BaseName
        }
        Write-Host ""
    }
    catch {
        Write-Host "✗ Error processing $($configFile.Name): $_" -ForegroundColor Red
        $failedEnvironments += $configFile.BaseName
    }
}

Write-Host "========================================" -ForegroundColor Cyan
if ($failedEnvironments.Count -eq 0) {
    Write-Host "✓ All environments rendered successfully!" -ForegroundColor Green
    exit 0
}
else {
    Write-Host "✗ Failed to render: $($failedEnvironments -join ', ')" -ForegroundColor Red
    exit 1
}

