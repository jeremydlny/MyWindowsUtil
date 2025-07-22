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
    @{Id = "qBittorrent.qBittorrent"; Name = "qBittorrent" },
    @{Id = "Piriform.CCleaner"; Name = "CCleaner" },
    @{Id = "Microsoft.PowerToys"; Name = "PowerToys" },
    @{Id = "Mozilla.Firefox"; Name = "Firefox" },
    @{Id = "Microsoft.VisualStudioCode"; Name = "Visual Studio Code" }
)

foreach ($app in $applications) {
    Install-Package -packageId $app.Id -packageName $app.Name
}