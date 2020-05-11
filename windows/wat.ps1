if($args.Count -ne 1)
{
    throw "wat must be called with 1 argument"
}


function IsInstalled([string] $command)
{
    & "where.exe" $command 2>&1 | Out-Null
    return $?
}

function DependencyInstalledCheck([string] $command)
{
    if(!(IsInstalled($command)))
    {
        throw "Dependency $command not installed, halting."
    }
}

function NoteExists([string] $name)
{
    Test-Path "~/notes/$name.md"
}

$command = $args[0]

if(IsInstalled("tldr")) {
    & "tldr" $command
}
else {
    & "curl" "cht.sh/$command"
}

if(NoteExists($command))
{
    DependencyInstalledCheck("mdcat")
    & "mdcat" (Resolve-Path "~/notes/$command.md")
}
