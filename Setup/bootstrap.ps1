# Windows Setup Bootstrap Script - Optimized Version

#Requires -RunAsAdministrator

Set-ExecutionPolicy Bypass -Scope Process -Force

# Log function (optimized)
$logDir = "$env:USERPROFILE\Documents\WindowsSetupLogs"
if (-not (Test-Path $logDir)) { New-Item -ItemType Directory -Path $logDir -Force | Out-Null }

$logPath = "$logDir\setup.log"
function Write-Log { 
    param([string]$m)
    $t = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $l = "[$t] $m"
    Write-Output $l
    # Use StringBuilder for better performance with many log entries
    Add-Content -Path $logPath -Value $l -Force
}

# Install Chris Titus Tech PowerShell profile (simplified)
Write-Log "Installing PowerShell profile..."
try {
    # Direct execution instead of background job to avoid serialization issues
    $profileScript = Invoke-RestMethod "https://github.com/ChrisTitusTech/powershell-profile/raw/main/setup.ps1"
    Invoke-Expression $profileScript
    Write-Log "PowerShell profile installed successfully."
}
catch {
    Write-Log "ERROR: Failed to install PowerShell profile - $($_.Exception.Message)"
}

# Optimized app installer with parallel execution
Write-Log "Looking for install_apps.ps1..."

# Simplified path resolution
$appsScript = $null
$possiblePaths = @(
    "$PSScriptRoot\Scripts\install_apps.ps1",
    "$PSScriptRoot\..\Setup\Scripts\install_apps.ps1",
    "$(Split-Path $PSScriptRoot -Parent)\Setup\Scripts\install_apps.ps1",
    "$(Get-Location)\Scripts\install_apps.ps1",
    "$(Get-Location)\Setup\Scripts\install_apps.ps1"
)

foreach ($path in $possiblePaths) {
    if (Test-Path $path) {
        $appsScript = $path
        Write-Log "Found install_apps.ps1 at: $appsScript"
        break
    }
}

# Fallback search if needed
if (-not $appsScript) {
    $found = Get-ChildItem -Path (Get-Location) -Name "install_apps.ps1" -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($found) {
        $appsScript = Join-Path (Get-Location) $found
        Write-Log "Found install_apps.ps1 via search: $appsScript"
    }
}

# Execute apps installation
if ($appsScript -and (Test-Path $appsScript)) {
    Write-Log "Executing optimized install_apps.ps1..."
    try {
        & $appsScript
        Write-Log "Apps installation completed successfully."
    }
    catch {
        Write-Log "ERROR: Failed to execute install_apps.ps1 - $($_.Exception.Message)"
    }
}
else {
    Write-Log "ERROR: Could not find install_apps.ps1"
    Write-Log "Skipping app installation."
}

# Launch Chris Titus Tech Windows Utility and download tweaks config
Write-Log "Downloading and launching Chris Titus Tech Windows Utility..."
try {
    # Download tweaks.json to Desktop first
    $desktop = [Environment]::GetFolderPath("Desktop")
    $tweaksJson = Join-Path $desktop "tweaks.json"
    $tweaksUrl = "https://raw.githubusercontent.com/jeremydlny/MyWindowsUtil/main/Setup/tweaks.json"
    
    Write-Host "📥 Downloading tweaks configuration to Desktop..." -ForegroundColor Cyan
    try {
        Invoke-WebRequest -Uri $tweaksUrl -OutFile $tweaksJson -UseBasicParsing -ErrorAction Stop
        Write-Log "Downloaded tweaks.json to Desktop."
        Write-Host "✅ tweaks.json downloaded to Desktop" -ForegroundColor Green
    }
    catch {
        Write-Log "WARNING: Could not download tweaks.json to Desktop - $($_.Exception.Message)"
        Write-Host "⚠️ Could not download tweaks.json" -ForegroundColor Yellow
    }

    # Launch Chris Titus Windows Utility
    Write-Host "🚀 Launching Chris Titus Windows Utility..." -ForegroundColor Cyan
    irm "https://christitus.com/win" | iex
    
    if (Test-Path $tweaksJson) {
        Write-Host "💡 Import your tweaks: Use 'Import' button in the utility and select tweaks.json from Desktop" -ForegroundColor Blue
    }
    
    Write-Log "Chris Titus Windows Utility launched successfully."
    
}
catch {
    Write-Log "ERROR: Failed to run Chris Titus Tech Windows Utility - $($_.Exception.Message)"
    Write-Host "❌ Could not launch Windows Utility. You can run it manually with: irm 'https://christitus.com/win' | iex" -ForegroundColor Red
}

Write-Log "Setup complete! Please restart your terminal."
Write-Host "`n🎉 Setup completed! Restart your terminal. Install fonts from CascadiaCode.zip if needed.`n" -ForegroundColor Green