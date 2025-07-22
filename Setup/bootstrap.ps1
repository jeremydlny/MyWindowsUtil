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
Write-Log "Looking for install_apps.ps1..."

# Déterminer le répertoire du script bootstrap.ps1
$scriptDirectory = $null

# Essayer plusieurs méthodes pour obtenir le répertoire du script
if ($PSScriptRoot -and $PSScriptRoot -ne "" -and (Test-Path $PSScriptRoot)) {
    $scriptDirectory = $PSScriptRoot
    Write-Log "Using PSScriptRoot: $scriptDirectory"
} elseif ($MyInvocation.MyCommand.Path -and $MyInvocation.MyCommand.Path -ne "" -and (Test-Path (Split-Path -Parent $MyInvocation.MyCommand.Path))) {
    $scriptDirectory = Split-Path -Parent $MyInvocation.MyCommand.Path
    Write-Log "Using MyInvocation path: $scriptDirectory"
} else {
    # Fallback: chercher dans le répertoire courant et ses parents
    $currentDir = Get-Location
    Write-Log "Fallback: searching from current directory: $currentDir"
    
    # Vérifier si on est dans le dossier Setup ou un sous-dossier
    if ($currentDir.Path -like "*Setup*" -or (Test-Path (Join-Path $currentDir "Scripts\install_apps.ps1"))) {
        $scriptDirectory = $currentDir
    } elseif (Test-Path (Join-Path $currentDir "Setup\Scripts\install_apps.ps1")) {
        $scriptDirectory = Join-Path $currentDir "Setup"
    }
}

# Chercher le script install_apps.ps1 dans la structure de projet
$appsScript = $null

if ($scriptDirectory) {
    # Structure attendue: MyWindowsUtil/Setup/Scripts/install_apps.ps1
    $possiblePaths = @(
        (Join-Path $scriptDirectory "Scripts\install_apps.ps1"),
        (Join-Path $scriptDirectory "..\Setup\Scripts\install_apps.ps1"),
        (Join-Path (Split-Path $scriptDirectory -Parent) "Setup\Scripts\install_apps.ps1")
    )
    
    foreach ($path in $possiblePaths) {
        Write-Log "Checking path: $path"
        if (Test-Path $path) {
            $appsScript = $path
            Write-Log "Found install_apps.ps1 at: $appsScript"
            break
        }
    }
}

# Si pas trouvé avec la structure, faire une recherche plus large
if (-not $appsScript) {
    Write-Log "Script not found in expected locations, searching more broadly..."
    
    # Recherche récursive depuis le répertoire courant
    $currentDir = Get-Location
    $found = Get-ChildItem -Path $currentDir -Name "install_apps.ps1" -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($found) {
        $appsScript = Join-Path $currentDir $found
        Write-Log "Found install_apps.ps1 via recursive search: $appsScript"
    }
}

# Exécuter le script s'il est trouvé
if ($appsScript -and (Test-Path $appsScript)) {
    Write-Log "Executing install_apps.ps1..."
    try {
        & $appsScript
        Write-Log "Apps installation completed successfully."
    } catch {
        Write-Log "ERROR: Failed to execute install_apps.ps1 - $($_.Exception.Message)"
    }
} else {
    Write-Log "ERROR: Could not find install_apps.ps1"
    Write-Log "Expected structure: MyWindowsUtil/Setup/Scripts/install_apps.ps1"
    Write-Log "Current working directory: $(Get-Location)"
    
    # Afficher les fichiers dans le répertoire courant pour debug
    if (Test-Path (Get-Location)) {
        Write-Log "Contents of current directory:"
        Get-ChildItem -Path (Get-Location) -Force | ForEach-Object { Write-Log "  - $($_.Name)" }
    }
    
    Write-Log "Skipping app installation."
}

Write-Log "Setup complete! Please restart your terminal."
Write-Host "`n🎉 Setup completed! Restart your terminal. Install fonts from CascadiaCode.zip if needed.`n" -ForegroundColor Green