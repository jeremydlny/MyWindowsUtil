# Install applications via winget

function Install-Package {
    param (
        [string]$packageId,
        [string]$packageName,
        [string]$installLocation = $null
    )
    Write-Host "Installing $packageName..."
    try {
        if ($installLocation) {
            Write-Host "Installing to: $installLocation"
            winget install --id $packageId --location $installLocation --accept-package-agreements --accept-source-agreements --silent
        } else {
            winget install --id $packageId --accept-package-agreements --accept-source-agreements --silent
        }
        Write-Host "Successfully installed $packageName" -ForegroundColor Green
    }
    catch {
        Write-Host "Failed to install $packageName : $_" -ForegroundColor Red
    }
}

$applications = @(
    @{Id = "Brave.Brave"; Name = "Brave Browser"; Location = $null },
    @{Id = "GitKraken.GitKraken"; Name = "GitKraken"; Location = $null },
    @{Id = "Discord.Discord"; Name = "Discord"; Location = $null },
    @{Id = "VideoLAN.VLC"; Name = "VLC Media Player"; Location = $null },
    @{Id = "ProtonTechnologies.ProtonVPN"; Name = "ProtonVPN"; Location = $null },
    @{Id = "Transmission.Transmission"; Name = "Transmission"; Location = $null },
    @{Id = "Microsoft.PowerToys"; Name = "PowerToys"; Location = $null },
    @{Id = "Mozilla.Firefox"; Name = "Firefox"; Location = $null },
    @{Id = "Microsoft.VisualStudioCode"; Name = "Visual Studio Code"; Location = $null },
    @{Id = "Valve.Steam"; Name = "Steam"; Location = $null },
    @{Id = "Blizzard.BattleNet"; Name = "BattleNet"; Location = "C:\Program Files (x86)" },
    @{Id = "Mozilla.Thunderbird.fr"; Name = "Thunderbird"; Location = $null },
    @{Id = "Notion.Notion"; Name = "Notion"; Location = $null },
    @{Id = "9PFHDD62MXS1"; Name = "Apple Music"; Location = $null },
    @{Id = "XP9CDQW6ML4NQN"; Name = "Plex"; Location = $null },
    @{Id = "XPFM11Z0W10R7G"; Name = "Plex Media Server"; Location = $null }
)

foreach ($app in $applications) {
    Install-Package -packageId $app.Id -packageName $app.Name -installLocation $app.Location
}