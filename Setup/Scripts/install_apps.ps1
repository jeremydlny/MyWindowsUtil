# Install applications via winget

function Install-Package {
    param (
        [string]$packageId,
        [string]$packageName
    )
    Write-Host "Installing $packageName..."
    try {
        winget install --id $packageId --accept-package-agreements --accept-source-agreements
        Write-Host "Successfully installed $packageName"
    }
    catch {
        Write-Host "Failed to install $packageName : $_"
    }
}

$applications = @(
    @{Id = "Brave.Brave"; Name = "Brave Browser" },
    @{Id = "GitKraken.GitKraken"; Name = "GitKraken" },
    @{Id = "Discord.Discord"; Name = "Discord" },
    @{Id = "VideoLAN.VLC"; Name = "VLC Media Player" },
    @{Id = "ProtonTechnologies.ProtonVPN"; Name = "ProtonVPN" },
    @{Id = "Transmission.Transmission "; Name = "Transmission" },
    @{Id = "Microsoft.PowerToys"; Name = "PowerToys" },
    @{Id = "Mozilla.Firefox"; Name = "Firefox" },
    @{Id = "Microsoft.VisualStudioCode"; Name = "Visual Studio Code" }
    @{Id = "Valve.Steam "; Name = "Valve.Steam " },
    @{Id = "Blizzard.BattleNet"; Name = "BattleNet" },
    @{Id = "Mozilla.Thunderbird.fr"; Name = "Thunderbird" },
    @{Id = "Notion.Notion"; Name = "Notion" },
    @{Id = "9PFHDD62MXS1"; Name = "Apple Music" },
    @{Id = "XP9CDQW6ML4NQN"; Name = "Plex" },
    @{Id = "XPFM11Z0W10R7G"; Name = "Plex Media Server" },

)

foreach ($app in $applications) {
    Install-Package -packageId $app.Id -packageName $app.Name
}