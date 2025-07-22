# Windows Setup Bootstrap Script

#Requires -RunAsAdministrator

Set-ExecutionPolicy Bypass -Scope Process -Force

# Log function
$logDir = "$env:USERPROFILE\Documents\WindowsSetupLogs"
if (-not (Test-Path $logDir)) { New-Item -ItemType Directory -Path $logDir | Out-Null }
function Write-Log { param([string]$m); $t = Get-Date -Format "yyyy-MM-dd HH:mm:ss"; $l = "[$t] $m"; Write-Output $l; Add-Content -Path "$logDir\setup.log" -Value $l }

# Install Chris Titus Tech PowerShell profile
Write-Log "Installing Chris Titus Tech PowerShell profile..."
irm "https://github.com/ChrisTitusTech/powershell-profile/raw/main/setup.ps1" | iex

# Run app installer script
Write-Log "Installing applications from Scripts\install_apps.ps1..."
$scriptRoot = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Definition }
$appsScript = Join-Path -Path $scriptRoot -ChildPath "..\Scripts\install_apps.ps1"
if (Test-Path $appsScript) {
    & $appsScript
} else {
    Write-Log "ERROR: Could not find install_apps.ps1 at $appsScript"
}

Write-Log "Setup complete! Please restart your terminal."
Write-Host "`n🎉 Setup completed! Restart your terminal. Install fonts from CascadiaCode.zip if needed.`n" -ForegroundColor Green