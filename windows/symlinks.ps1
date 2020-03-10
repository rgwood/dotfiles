# Symlink setup:

New-Item -ItemType symboliclink -Path "$HOME\OneDrive\Documents\PowerShell\profile.ps1" -Value "$HOME\dotfiles\windows\powershellProfile.ps1" -Force

# Is there any difference between $HOME and $Env:Userprofile?
New-Item -ItemType symboliclink -Path "$Env:Userprofile\.npmrc" -Value "$Env:Userprofile\dotfiles\Windows\npmrc"