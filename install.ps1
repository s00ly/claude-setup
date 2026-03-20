# ──────────────────────────────────────────────────────────
# Claude Code Project Setup — s00ly
# Installs global slash commands for all projects.
# PowerShell version for Windows (no admin required).
# ──────────────────────────────────────────────────────────

$ErrorActionPreference = "Stop"

$ScriptDir   = Split-Path -Parent $MyInvocation.MyCommand.Path
$CommandsSrc = Join-Path $ScriptDir "commands"
$CommandsDst = Join-Path $env:USERPROFILE ".claude\commands"

# Create target directory
if (-not (Test-Path $CommandsDst)) {
    New-Item -ItemType Directory -Path $CommandsDst -Force | Out-Null
}

Write-Host ""
Write-Host "  Claude Code - Project Setup"
Write-Host "  --------------------------------"
Write-Host ""

$installed = @()

Get-ChildItem "$CommandsSrc\*.md" | ForEach-Object {
    $dest = Join-Path $CommandsDst $_.Name
    Copy-Item $_.FullName $dest -Force
    $cmdName = $_.BaseName
    $installed += "/$cmdName"
    Write-Host "  + /$cmdName"
}

Write-Host ""
Write-Host "  Installed $($installed.Count) command(s): $($installed -join ', ')"
Write-Host ""
Write-Host "  To update commands later: pull this repo and re-run install.ps1"
Write-Host ""
Write-Host "  Open Claude Code and type any command to start."
Write-Host ""
