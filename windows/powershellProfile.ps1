Set-Alias -Name which -Value where.exe

Function Touch-File ($fileName) { New-Item -ItemType file $fileName }
Set-Alias -Name touch -Value Touch-File

Import-Module PSFzf -ArgumentList 'Ctrl+t','Ctrl+r'

function Get-HelpCustom ($command) {
    Get-Help $command | less
}
Set-Alias gh Get-HelpCustom

function Get-Examples ($command) {
    Get-Help $command -Examples | less
}
Set-Alias ghe Get-Examples

function Get-DetailedHelp ($command) {
    Get-Help $command -Detailed | less
}
Set-Alias ghd Get-DetailedHelp

Invoke-Expression (&starship init powershell)