`ctrl-t` to insert
`ctrl-r` to search command history
`alt-c` to cd to directory

Launch with a `bat` preview for files: 
`fzf --preview 'bat --color always {}'`
And put the result on the Fish command line:
`commandline (fzf --preview 'bat --color always {}')`