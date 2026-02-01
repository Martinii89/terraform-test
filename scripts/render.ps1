#!/usr/bin/env pwsh
# Helper script to regenerate rendered config files from templates
# Usage: .\scripts\render.ps1 -Environment staging -DomainName terraform.martinn.no -LetsencryptEmail m4rtini89@gmail.com
# Or: .\scripts\render.ps1 staging terraform.martinn.no m4rtini89@gmail.com

param(
    [Parameter(Position = 0)]
    [string]$Environment = "staging",
    
    [Parameter(Position = 1)]
    [string]$DomainName,
    
    [Parameter(Position = 2)]
    [string]$LetsencryptEmail
)

if (-not $DomainName -or -not $LetsencryptEmail) {
    Write-Host "Usage: .\render.ps1 <environment> <domain_name> <letsencrypt_email>" -ForegroundColor Yellow
    Write-Host "Example: .\render.ps1 staging terraform.martinn.no m4rtini89@gmail.com" -ForegroundColor Yellow
    exit 1
}

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Split-Path -Parent $ScriptDir
$TemplatesDir = Join-Path $ProjectRoot "templates" "infra"
$RenderedDir = Join-Path $ProjectRoot "rendered" $Environment

Write-Host "Rendering templates for $Environment environment..." -ForegroundColor Cyan
Write-Host "  Domain: $DomainName" -ForegroundColor Gray
Write-Host "  Email: $LetsencryptEmail" -ForegroundColor Gray

# Set environment variables for template substitution
$env:DOMAIN_NAME = $DomainName
$env:LETSENCRYPT_EMAIL = $LetsencryptEmail

# Ensure rendered directories exist
$null = New-Item -ItemType Directory -Path (Join-Path $RenderedDir "nginx" "sites") -Force

# Function to render template with environment variable substitution
function Render-Template {
    param(
        [string]$TemplateFile,
        [string]$OutputFile
    )
    
    if (-not (Test-Path $TemplateFile)) {
        Write-Host "✗ Template not found: $TemplateFile" -ForegroundColor Red
        exit 1
    }
    
    # Check if envsubst is available (from Git Bash, WSL, or GNU utils)
    $envsubstAvailable = $null -ne (Get-Command envsubst -ErrorAction SilentlyContinue)
    
    if ($envsubstAvailable) {
        # Use envsubst for robust variable substitution
        Get-Content -Path $TemplateFile -Raw | envsubst | Set-Content -Path $OutputFile -NoNewline
    }
    else {
        # Fallback: use environment variables for substitution
        # This approach substitutes all ${VARNAME} patterns
        $content = Get-Content -Path $TemplateFile -Raw
        
        # Get all environment variables and replace ${VAR} patterns
        Get-ChildItem env: | ForEach-Object {
            $pattern = '\$\{' + [regex]::Escape($_.Name) + '\}'
            $content = $content -replace $pattern, $_.Value
        }
        
        Set-Content -Path $OutputFile -Value $content -NoNewline
    }
    
    Write-Host "✓ Rendered $(Split-Path -Leaf $OutputFile)" -ForegroundColor Green
}

# Function to copy file without rendering
function Copy-StaticFile {
    param(
        [string]$SourceFile,
        [string]$DestFile
    )
    
    $null = New-Item -ItemType Directory -Path (Split-Path -Parent $DestFile) -Force
    Copy-Item -Path $SourceFile -Destination $DestFile -Force
    Write-Host "✓ Copied $(Split-Path -Leaf $DestFile)" -ForegroundColor Green
}

# Recursively process all files in templates directory
function Process-TemplateDirectory {
    param(
        [string]$SourceDir,
        [string]$DestDir
    )
    
    # Ensure destination exists
    $null = New-Item -ItemType Directory -Path $DestDir -Force
    
    # Get all files recursively
    Get-ChildItem -Path $SourceDir -Recurse -File | ForEach-Object {
        $relativePath = $_.FullName.Substring($SourceDir.Length + 1)
        $destFile = Join-Path $DestDir $relativePath
        
        if ($_.Name -match '\.tpl$') {
            # Remove .tpl extension from output filename
            $destFile = $destFile -replace '\.tpl$', ''
            Render-Template -TemplateFile $_.FullName -OutputFile $destFile
        }
        else {
            # Copy static files as-is
            Copy-StaticFile -SourceFile $_.FullName -DestFile $destFile
        }
    }
}

# Render templates for the specified environment
Process-TemplateDirectory -SourceDir $TemplatesDir -DestDir $RenderedDir

Write-Host "Rendering complete! Output in: $RenderedDir" -ForegroundColor Green
