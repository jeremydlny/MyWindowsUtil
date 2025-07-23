# Optimized Application Installer with Pre-Installation Check and Parallel Execution

# Function to check if an application is already installed
function Test-AppInstalled {
    param (
        [string]$packageId,
        [string]$packageName
    )
    
    try {
        # Method 1: Check with winget list (most reliable)
        $wingetResult = winget list --id $packageId 2>$null
        if ($LASTEXITCODE -eq 0 -and $wingetResult -like "*$packageId*") {
            return $true
        }
        
        # Method 2: Specific path checks for common applications
        switch ($packageId) {
            "Brave.Brave" { 
                return (Test-Path "$env:LOCALAPPDATA\BraveSoftware\Brave-Browser\Application\brave.exe") -or
                (Test-Path "$env:PROGRAMFILES\BraveSoftware\Brave-Browser\Application\brave.exe")
            }
            "Discord.Discord" { 
                return Test-Path "$env:LOCALAPPDATA\Discord\Update.exe"
            }
            "Microsoft.VisualStudioCode" { 
                return (Test-Path "$env:LOCALAPPDATA\Programs\Microsoft VS Code\Code.exe") -or
                (Test-Path "$env:PROGRAMFILES\Microsoft VS Code\Code.exe")
            }
            "Valve.Steam" { 
                return Test-Path "$env:PROGRAMFILES(X86)\Steam\Steam.exe"
            }
            "Blizzard.BattleNet" { 
                return Test-Path "$env:PROGRAMFILES(X86)\Battle.net\Battle.net Launcher.exe"
            }
            "VideoLAN.VLC" { 
                return (Test-Path "$env:PROGRAMFILES\VideoLAN\VLC\vlc.exe") -or
                (Test-Path "$env:PROGRAMFILES(X86)\VideoLAN\VLC\vlc.exe")
            }
            "Microsoft.PowerToys" {
                return Test-Path "$env:LOCALAPPDATA\Microsoft\WindowsApps\PowerToys.exe"
            }
            "AgileBits.1Password" {
                return Test-Path "$env:LOCALAPPDATA\1password\app\8\1Password.exe"
            }
        }
        
        return $false
    }
    catch {
        return $false
    }
}

# Filter out already installed applications
function Get-AppsToInstall {
    param([array]$Apps)
    
    $appsToInstall = @()
    $alreadyInstalled = @()
    
    foreach ($app in $Apps) {
        if (Test-AppInstalled -packageId $app.Id -packageName $app.Name) {
            $alreadyInstalled += $app.Name
        }
        else {
            $appsToInstall += $app
        }
    }
    
    if ($alreadyInstalled.Count -gt 0) {
        Write-Host "⏩ Already installed: $($alreadyInstalled -join ', ')" -ForegroundColor Green
    }
    
    return $appsToInstall
}

# Optimized application list with priority grouping
$criticalApps = @(
    @{Id = "Microsoft.VisualStudioCode"; Name = "Visual Studio Code"; Location = $null },
    @{Id = "Brave.Brave"; Name = "Brave Browser"; Location = $null },
    @{Id = "Microsoft.PowerToys"; Name = "PowerToys"; Location = $null },
    @{Id = "AgileBits.1Password"; Name = "1Password"; Location = $null }
)

$standardApps = @(
    @{Id = "GitKraken.GitKraken"; Name = "GitKraken"; Location = $null },
    @{Id = "Discord.Discord"; Name = "Discord"; Location = $null },
    @{Id = "VideoLAN.VLC"; Name = "VLC Media Player"; Location = $null },
    @{Id = "ProtonTechnologies.ProtonVPN"; Name = "ProtonVPN"; Location = $null },
    @{Id = "Mozilla.Firefox"; Name = "Firefox"; Location = $null },
    @{Id = "Mozilla.Thunderbird.fr"; Name = "Thunderbird"; Location = $null },
    @{Id = "Notion.Notion"; Name = "Notion"; Location = $null }
)

$heavyApps = @(
    @{Id = "Valve.Steam"; Name = "Steam"; Location = $null },
    @{Id = "Blizzard.BattleNet"; Name = "BattleNet"; Location = "C:\Program Files (x86)" },
    @{Id = "9PFHDD62MXS1"; Name = "Apple Music"; Location = $null },
    @{Id = "XP9CDQW6ML4NQN"; Name = "Plex"; Location = $null },
    @{Id = "XPFM11Z0W10R7G"; Name = "Plex Media Server"; Location = $null }
)

# Function to install apps with threading (using runspaces instead of jobs)
function Install-AppsParallel {
    param(
        [array]$Apps,
        [int]$BatchSize = 3,
        [string]$GroupName
    )
    
    if ($Apps.Count -eq 0) {
        Write-Host "✅ All $GroupName applications are already installed!" -ForegroundColor Green
        return
    }
    
    Write-Host "`n🚀 Installing $($Apps.Count) $GroupName applications..." -ForegroundColor Cyan
    
    # Create runspace pool for better performance
    $runspacePool = [runspacefactory]::CreateRunspacePool(1, $BatchSize)
    $runspacePool.Open()
    
    $runspaces = @()
    
    foreach ($app in $Apps) {
        $runspace = [powershell]::Create()
        $runspace.RunspacePool = $runspacePool
        
        [void]$runspace.AddScript({
                param($packageId, $packageName, $installLocation)
            
                try {
                    $wingetArgs = @(
                        "install",
                        "--id", $packageId,
                        "--accept-package-agreements",
                        "--accept-source-agreements",
                        "--silent",
                        "--disable-interactivity"
                    )
                
                    if ($installLocation) {
                        $wingetArgs += "--location"
                        $wingetArgs += $installLocation
                    }
                
                    # Use direct winget execution
                    $output = & winget @wingetArgs 2>&1
                    $exitCode = $LASTEXITCODE
                
                    if ($exitCode -eq 0) {
                        return @{ 
                            Success = $true; 
                            Status  = "installed"
                            Message = "Successfully installed $packageName"
                            App     = $packageName
                        }
                    }
                    elseif ($exitCode -eq -1978335189 -or $exitCode -eq -1978335226 -or $exitCode -eq -1978335212) {
                        # Already installed codes
                        return @{ 
                            Success = $true; 
                            Status  = "already_installed"
                            Message = "$packageName was already installed"
                            App     = $packageName
                        }
                    }
                    else {
                        return @{ 
                            Success = $false; 
                            Status  = "failed"
                            Message = "Failed to install $packageName (Exit code: $exitCode)"
                            App     = $packageName
                        }
                    }
                }
                catch {
                    return @{ 
                        Success = $false; 
                        Status  = "error"
                        Message = "Failed to install $packageName : $($_.Exception.Message)"
                        App     = $packageName
                    }
                }
            })
        
        [void]$runspace.AddParameter("packageId", $app.Id)
        [void]$runspace.AddParameter("packageName", $app.Name)
        [void]$runspace.AddParameter("installLocation", $app.Location)
        
        $runspaces += @{
            Runspace = $runspace
            Handle   = $runspace.BeginInvoke()
            App      = $app.Name
        }
    }
    
    # Wait for all runspaces to complete and collect results
    $successful = 0
    $failed = 0
    
    foreach ($rs in $runspaces) {
        try {
            $result = $rs.Runspace.EndInvoke($rs.Handle)
            $rs.Runspace.Dispose()
            
            if ($result.Success -and $result.Status -eq "installed") {
                Write-Host "✅ $($result.Message)" -ForegroundColor Green
                $successful++
            }
            elseif ($result.Success -and $result.Status -eq "already_installed") {
                Write-Host "⚠️ $($result.Message)" -ForegroundColor Yellow
                $successful++
            }
            else {
                Write-Host "❌ $($result.Message)" -ForegroundColor Red
                $failed++
            }
        }
        catch {
            Write-Host "❌ Error installing $($rs.App): $($_.Exception.Message)" -ForegroundColor Red
            $failed++
        }
    }
    
    $runspacePool.Close()
    $runspacePool.Dispose()
    
    Write-Host "📊 $GroupName group: $successful successful, $failed failed" -ForegroundColor Cyan
}

# Pre-flight check: Update winget sources
Write-Host "🔄 Updating winget sources..." -ForegroundColor Yellow
try {
    winget source update --disable-interactivity | Out-Null
    Write-Host "✅ Winget sources updated" -ForegroundColor Green
}
catch {
    Write-Host "⚠️ Warning: Could not update winget sources" -ForegroundColor Yellow
}

Write-Host "`n🔍 Checking which applications need to be installed..." -ForegroundColor Magenta

# Filter applications and install in priority order with parallel execution
$criticalToInstall = Get-AppsToInstall -Apps $criticalApps
Install-AppsParallel -Apps $criticalToInstall -BatchSize 2 -GroupName "Critical"

# Small delay between groups to avoid overwhelming the system
if ($criticalToInstall.Count -gt 0) { Start-Sleep -Seconds 2 }

$standardToInstall = Get-AppsToInstall -Apps $standardApps
Install-AppsParallel -Apps $standardToInstall -BatchSize 3 -GroupName "Standard"

if ($standardToInstall.Count -gt 0) { Start-Sleep -Seconds 2 }

$heavyToInstall = Get-AppsToInstall -Apps $heavyApps
Install-AppsParallel -Apps $heavyToInstall -BatchSize 2 -GroupName "Heavy"

$totalOriginal = $criticalApps.Count + $standardApps.Count + $heavyApps.Count
$totalToInstall = $criticalToInstall.Count + $standardToInstall.Count + $heavyToInstall.Count
$totalSkipped = $totalOriginal - $totalToInstall

Write-Host "`n" + "=" * 60 -ForegroundColor Gray
Write-Host "🎉 Installation Summary:" -ForegroundColor Magenta
Write-Host "   📊 Total applications: $totalOriginal" -ForegroundColor White
Write-Host "   ⏩ Already installed: $totalSkipped" -ForegroundColor Green
Write-Host "   📦 Newly processed: $totalToInstall" -ForegroundColor Blue
Write-Host "=" * 60 -ForegroundColor Gray