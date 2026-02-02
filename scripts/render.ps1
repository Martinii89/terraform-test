#!/usr/bin/env pwsh
# Helper script to regenerate rendered config files from templates using Jinja2
# Usage: .\scripts\render.ps1 -ConfigFile ./configs/staging.yaml

param(
    [Parameter()]
    [string]$ConfigFile
)

# Validate parameters
if (-not $ConfigFile) {
    Write-Host "Usage: .\render.ps1 -ConfigFile <path-to-config.yaml>" -ForegroundColor Yellow
    Write-Host "Example: .\render.ps1 -ConfigFile ./configs/staging.yaml" -ForegroundColor Yellow
    exit 1
}

# Resolve paths
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Split-Path -Parent $ScriptDir
$resolvedConfigFile = Resolve-Path -Path $ConfigFile -ErrorAction SilentlyContinue

if (-not $resolvedConfigFile) {
    Write-Host "Error: Config file not found: $ConfigFile" -ForegroundColor Red
    exit 1
}

# Extract environment name from config filename
$ConfigFileName = Split-Path -Leaf $resolvedConfigFile
$Environment = [System.IO.Path]::GetFileNameWithoutExtension($ConfigFileName)

$TemplatesDir = Join-Path $ProjectRoot "templates" "infra"
$RenderedDir = Join-Path $ProjectRoot "rendered" $Environment
$PythonScript = Join-Path $ScriptDir "render-templates.py"

# Check if Python is available
$python = Get-Command py -ErrorAction SilentlyContinue
if (-not $python) {
    $python = Get-Command python -ErrorAction SilentlyContinue
}
if (-not $python) {
    $python = Get-Command python3 -ErrorAction SilentlyContinue
}

if (-not $python) {
    Write-Host "Error: Python not found. Please install Python 3." -ForegroundColor Red
    exit 1
}

# Check if Jinja2 and PyYAML are installed
Write-Host "Checking Python dependencies..." -ForegroundColor Gray
& $python -c "import jinja2, yaml" 2>$null
if ($LASTEXITCODE -ne 0) {
    Write-Host "Installing Python dependencies (Jinja2, PyYAML)..." -ForegroundColor Yellow
    & $python -m pip install jinja2 pyyaml --quiet
}

Write-Host "Rendering templates for $Environment environment..." -ForegroundColor Cyan
Write-Host "  Config: $resolvedConfigFile" -ForegroundColor Gray
Write-Host "  Templates: $TemplatesDir" -ForegroundColor Gray
Write-Host "  Output: $RenderedDir" -ForegroundColor Gray

# Call Python script to render templates
& $python $PythonScript $resolvedConfigFile $TemplatesDir $RenderedDir

if ($LASTEXITCODE -eq 0) {
    Write-Host "✓ Rendering complete!" -ForegroundColor Green
    exit 0
}
else {
    Write-Host "✗ Rendering failed!" -ForegroundColor Red
    exit 1
}

