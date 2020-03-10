Set-Alias -Name which -Value where.exe

Set-Alias -Name touch -Value Touch-File
Function Touch-File ($fileName) { New-Item -ItemType file $fileName }


Import-Module PSFzf -ArgumentList 'Ctrl+t','Ctrl+r'