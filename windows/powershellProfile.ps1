# Aliases
Set-Alias -Name which -Value where.exe

function touch ($fileName) { New-Item -ItemType file $fileName }

function gh ($command) { Get-Help $command | less }
function ghe ($command) { Get-Help $command -Examples | less }
function ghd ($command) { Get-Help $command -Detailed | less}

function mkd ($dirName) { mkdir $dirName | Out-Null; cd $dirName;}

function gs(){git status}

# Keybindings
Set-PSReadLineKeyHandler -key Tab -Function MenuComplete

# Imports
Import-Module PSFzf -ArgumentList 'Ctrl+t','Ctrl+r'

# Starship prompt
Invoke-Expression (&starship init powershell)