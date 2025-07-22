# Windows Setup Bootstrap Script

#Requires -RunAsAdministrator

Set-ExecutionPolicy Bypass -Scope Process -Force

# Log function
$logDir = "$env:USERPROFILE\Documents\WindowsSetupLogs"
if (-not (Test-Path $logDir)) { New-Item -ItemType Directory -Path $logDir | Out-Null }
function Write-Log { 
    param([string]$m)
    $t = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $l = "[$t] $m"
    Write-Output $l
    Add-Content -Path "$logDir\setup.log" -Value $l
}

# Install Chris Titus Tech PowerShell profile
Write-Log "Installing Chris Titus Tech PowerShell profile..."
try {
    irm "https://github.com/ChrisTitusTech/powershell-profile/raw/main/setup.ps1" | iex
    Write-Log "PowerShell profile installed successfully."
} catch {
    Write-Log "ERROR: Failed to install PowerShell profile - $($_.Exception.Message)"
}

# Run app installer script
Write-Log "Installing applications from Scripts\install_apps.ps1..."

# Déterminer le répertoire racine du script de manière plus robuste
$scriptRoot = $null

if ($PSScriptRoot -and $PSScriptRoot -ne "") {
    $scriptRoot = $PSScriptRoot
    Write-Log "Using PSScriptRoot: $scriptRoot"
} elseif ($MyInvocation.MyCommand.Path -and $MyInvocation.MyCommand.Path -ne "") {
    $scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
    Write-Log "Using MyInvocation path: $scriptRoot"
} else {
    # Fallback: utiliser le répertoire de travail actuel
    $scriptRoot = Get-Location
    Write-Log "Using current location as fallback: $scriptRoot"
}

if ($scriptRoot) {
    $appsScript = Join-Path -Path $scriptRoot -ChildPath "..\Scripts\install_apps.ps1"
    Write-Log "Looking for apps script at: $appsScript"
    
    if (Test-Path $appsScript) {
        Write-Log "Found install_apps.ps1, executing..."
        try {
            & $appsScript
            Write-Log "Apps installation completed successfully."
        } catch {
            Write-Log "ERROR: Failed to execute install_apps.ps1 - $($_.Exception.Message)"
        }
    } else {
        Write-Log "ERROR: Could not find install_apps.ps1 at $appsScript"
        Write-Log "Current directory contents:"
        Get-ChildItem -Path $scriptRoot | ForEach-Object { Write-Log "  - $($_.Name)" }
        
        # Chercher le fichier dans d'autres emplacements possibles
        $possiblePaths = @(
            Join-Path -Path $scriptRoot -ChildPath "Scripts\install_apps.ps1",
            Join-Path -Path $scriptRoot -ChildPath "install_apps.ps1",
            Join-Path -Path (Split-Path $scriptRoot) -ChildPath "Scripts\install_apps.ps1"
        )
        
        foreach ($path in $possiblePaths) {
            if (Test-Path $path) {
                Write-Log "Found install_apps.ps1 at alternative location: $path"
                try {
                    & $path
                    Write-Log "Apps installation completed successfully from alternative location."
                    break
                } catch {
                    Write-Log "ERROR: Failed to execute install_apps.ps1 from $path - $($_.Exception.Message)"
                }
            }
        }
    }
} else {
    Write-Log "ERROR: Could not determine script root directory"
}

Write-Log "Setup complete! Please restart your terminal."
Write-Host "`n🎉 Setup completed! Restart your terminal. Install fonts from CascadiaCode.zip if needed.`n" -ForegroundColor Green