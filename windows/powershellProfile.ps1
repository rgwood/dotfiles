# Aliases
Set-Alias -Name which -Value where.exe

function touch ($fileName) { New-Item -ItemType file $fileName }

function gh ($command) { Get-Help $command | less }
function ghe ($command) { Get-Help $command -Examples | less }
function ghd ($command) { Get-Help $command -Detailed | less}

function mkd ($dirName) { mkdir $dirName | Out-Null; cd $dirName;}

# macOS open command
function open(){explorer}
function gs(){git status}
function gitlog(){git log --oneline --graph}
function lg(){lazygit}

# Keybindings
Set-PSReadLineKeyHandler -key Tab -Function MenuComplete

# Imports
Import-Module PSFzf -ArgumentList 'Ctrl+t','Ctrl+r'

# Starship prompt
Invoke-Expression (&starship init powershell)

Set-Alias -Name wat -Value wat.ps1

# $env:DOTNET_CLI_TELEMETRY_OPTOUT = 1