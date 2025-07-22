# Optimized Application Installer with Parallel Execution

# Enhanced package installation with better error handling
function Install-Package {
    param (
        [string]$packageId,
        [string]$packageName,
        [string]$installLocation = $null
    )
    
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
        
        # Execute winget with timeout
        $process = Start-Process -FilePath "winget" -ArgumentList $wingetArgs -NoNewWindow -Wait -PassThru
        
        if ($process.ExitCode -eq 0) {
            return @{ Success = $true; Message = "Successfully installed $packageName" }
        } else {
            return @{ Success = $false; Message = "Failed to install $packageName (Exit code: $($process.ExitCode))" }
        }
    }
    catch {
        return @{ Success = $false; Message = "Failed to install $packageName : $_" }
    }
}

# Optimized application list with priority grouping
$criticalApps = @(
    @{Id = "Microsoft.VisualStudioCode"; Name = "Visual Studio Code"; Location = $null },
    @{Id = "Brave.Brave"; Name = "Brave Browser"; Location = $null },
    @{Id = "Microsoft.PowerToys"; Name = "PowerToys"; Location = $null }
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
    @{Id = "Transmission.Transmission"; Name = "Transmission"; Location = $null },
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
    
    Write-Host "`n🚀 Installing $GroupName applications..." -ForegroundColor Cyan
    
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
                    "--disable-interactivity",
                    "--force"
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
                        Status = "installed"
                        Message = "Successfully installed $packageName"
                        App = $packageName
                    }
                } elseif ($exitCode -eq -1978335189 -or $exitCode -eq -1978335226 -or $exitCode -eq -1978335212) { # Already installed codes
                    return @{ 
                        Success = $true; 
                        Status = "already_installed"
                        Message = "$packageName is already installed"
                        App = $packageName
                    }
                } else {
                    return @{ 
                        Success = $false; 
                        Status = "failed"
                        Message = "Failed to install $packageName (Exit code: $exitCode)"
                        App = $packageName
                    }
                }
            }
            catch {
                return @{ 
                    Success = $false; 
                    Status = "error"
                    Message = "Failed to install $packageName : $($_.Exception.Message)"
                    App = $packageName
                }
            }
        })
        
        [void]$runspace.AddParameter("packageId", $app.Id)
        [void]$runspace.AddParameter("packageName", $app.Name)
        [void]$runspace.AddParameter("installLocation", $app.Location)
        
        $runspaces += @{
            Runspace = $runspace
            Handle = $runspace.BeginInvoke()
            App = $app.Name
        }
    }
    
    # Wait for all runspaces to complete and collect results
    foreach ($rs in $runspaces) {
        try {
            $result = $rs.Runspace.EndInvoke($rs.Handle)
            $rs.Runspace.Dispose()
            
            if ($result.Success -and $result.Status -eq "installed") {
                Write-Host "✅ $($result.Message)" -ForegroundColor Green
            } elseif ($result.Success -and $result.Status -eq "already_installed") {
                Write-Host "⚠️ $($result.Message)" -ForegroundColor Yellow
            } else {
                Write-Host "❌ $($result.Message)" -ForegroundColor Red
            }
        }
        catch {
            Write-Host "❌ Error installing $($rs.App): $($_.Exception.Message)" -ForegroundColor Red
        }
    }
    
    $runspacePool.Close()
    $runspacePool.Dispose()
}

# Pre-flight check: Update winget sources
Write-Host "🔄 Updating winget sources..." -ForegroundColor Yellow
try {
    winget source update --disable-interactivity | Out-Null
} catch {
    Write-Host "⚠️ Warning: Could not update winget sources" -ForegroundColor Yellow
}

# Install applications in priority order with parallel execution
Install-AppsParallel -Apps $criticalApps -BatchSize 2 -GroupName "Critical"

# Small delay between groups to avoid overwhelming the system
Start-Sleep -Seconds 2

Install-AppsParallel -Apps $standardApps -BatchSize 3 -GroupName "Standard"

Start-Sleep -Seconds 2

Install-AppsParallel -Apps $heavyApps -BatchSize 2 -GroupName "Heavy"

Write-Host "`n🎉 All applications installation completed!" -ForegroundColor Green