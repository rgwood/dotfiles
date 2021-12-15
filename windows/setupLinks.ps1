# PS profile: Current user, all hosts
New-Item -ItemType symboliclink -Path "$HOME\OneDrive\Documents\PowerShell\profile.ps1" -Value "$HOME\dotfiles\windows\powershellProfile.ps1" -Force

# Is there any difference between $HOME and $Env:Userprofile?
New-Item -ItemType symboliclink -Path "$Env:Userprofile\.npmrc" -Value "$Env:Userprofile\dotfiles\Windows\npmrc"

# Hardlink b/c Windows Terminal settings don't auto-reload with symlinks
# https://github.com/microsoft/terminal/issues/1812
# New-Item -ItemType HardLink -Path "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\profiles.json"  -Value "$HOME\dotfiles\windows\WindowsTerminalProfiles.json" -Confirm -Force

New-Item -ItemType symboliclink -Path "$HOME\.config\starship.toml" -Value "$HOME\dotfiles\starship.toml" -Force

New-Item -ItemType symboliclink -Path "$HOME\scripts" -Value "$HOME\dotfiles\scripts\win" -Force

New-Item -ItemType symboliclink -Path "$env:AppData\lazygit\config.yml" -Value "$HOME\dotfiles\Windows\lazygit-config.yml" -Force