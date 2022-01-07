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

# .NET stuff

Add-Type -Language CSharp @"
using System;
using System.Runtime.InteropServices;
namespace Profile;

public static class Utils
{
	public static string GetRid()
	{
		string os;

		if (RuntimeInformation.IsOSPlatform(OSPlatform.OSX))
			os = "osx";
		else if (RuntimeInformation.IsOSPlatform(OSPlatform.Windows))
			os = "win";
		else if (RuntimeInformation.IsOSPlatform(OSPlatform.Linux))
			os = "linux";
		else
			throw new Exception("Unsupported OS");

		string arch = RuntimeInformation.OSArchitecture switch
		{
			Architecture.X64 => "x64",
			Architecture.Arm64 => "arm64",
			Architecture.X86 => "x86",
			Architecture.Arm => "arm",
			_ => throw new Exception("Unsupported architecture")
		};

		return $"{os}-{arch}";
	}
}
"@;

function build-singlefile($rid) 
{
    $rid = $rid ?? [Profile.Utils]::GetRid()
    dotnet publish --configuration Release --runtime $rid --self-contained true -p:PublishSingleFile=true -p:IncludeAllContentForSelfExtract=true -p:DebugType=embedded --output .
}

# Keybindings
Set-PSReadLineKeyHandler -key Tab -Function MenuComplete

# Imports
Import-Module PSFzf -ArgumentList 'Ctrl+t','Ctrl+r'

# Starship prompt
Invoke-Expression (&starship init powershell)

Set-Alias -Name wat -Value wat.ps1

# $env:DOTNET_CLI_TELEMETRY_OPTOUT = 1