# MyWindowsUtil

Automated setup script for configuring your Windows terminal with essential tools and customizations.

## Features

- Installs Chris Titus Tech PowerShell profile
- Installs Cascadia Code Nerd Font
- Installs your favorite applications via winget
- Simple configuration override system

## Requirements

- Windows 10/11
- Administrator privileges
- Internet connection

## Installation

1. **Open PowerShell as Administrator**
2. **Run:**
   ```powershell
   Set-ExecutionPolicy Bypass -Scope Process -Force; irm https://raw.githubusercontent.com/jeremydlny/MyWindowsUtil/main/Setup/bootstrap.ps1 | iex
   ```

## What the script does

- Installs the Chris Titus Tech PowerShell profile for a modern terminal experience
- Downloads Cascadia Code Nerd Font (`CascadiaCode.zip`) to your temp folder
- Installs the following applications via winget:
  - Brave Browser
  - GitKraken
  - Discord
  - VLC Media Player
  - ProtonVPN
  - qBittorrent
  - CCleaner
  - PowerToys
  - Firefox
  - Visual Studio Code

## Post-Installation

1. **Install the font:**  
   Extract and install all fonts from `CascadiaCode.zip` (found in your temp folder).
2. **Restart your terminal** for the profile and fonts to take effect.

## Customization

- Place your overrides and custom variables in `Config/default.ps1`.
- To add or remove applications, edit `Scripts/install_apps.ps1`.

## License

MIT License

---

Created by [Jeremy Delannoy](https://github.com/jeremydlny)
