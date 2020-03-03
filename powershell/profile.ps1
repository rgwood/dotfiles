# ctrl-space autocomplete doesn't work on Mac, I think because that shortcut is reserved for some control char.
# Can fix by setting up a new mapping with a Unicode private use char and setting iTerm2 to map ctrl-space to that char.
# https://github.com/PowerShell/PSReadLine/issues/639#issuecomment-490927138
`Set-PSReadLineKeyHandler -Key '' -Function MenuComplete`