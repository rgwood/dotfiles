# Nushell Environment Config File

$env.RUST_BACKTRACE = 1

if (sys host | get hostname) == "framework-fry" {
    # $env.DOTNET_ROOT = "/home/linuxbrew/.linuxbrew/opt/dotnet/libexec"

    $env.DOTNET_ROOT = "/home/reilly/.dotnet/"
}

# *nix locale
$env.LC_ALL = "en_US.UTF-8"

# ─── BEGIN mirrored block ───
# Keep in sync with zsh/zshrc and nu/config.nu (manual sync, no codegen)
# Precedence: terminal shims, Volta, ~/bin, Homebrew, inherited PATH,
# then Cargo, ~/.local/bin and .NET. Keep the first copy of each entry.

$env.EDITOR = "micro"
$env.VISUAL = "micro"

if (sys host | get name) == "Darwin" {
    $env.PATH = ($env.PATH | split row (char esep) | prepend '/opt/homebrew/bin')
} else {
    $env.PATH = ($env.PATH | split row (char esep) | prepend /home/linuxbrew/.linuxbrew/bin)
}

$env.PATH = ($env.PATH | split row (char esep) | prepend $"($env.HOME)/bin" )
$env.PATH = ($env.PATH | split row (char esep) | append $"($env.HOME)/.cargo/bin" )
$env.PATH = ($env.PATH | split row (char esep) | prepend $"($env.HOME)/.volta/bin" )
$env.PATH = ($env.PATH | split row (char esep) | append $"($env.HOME)/.local/bin" )
$env.PATH = ($env.PATH | split row (char esep) | append $"($env.HOME)/.dotnet" )
$env.PATH = ($env.PATH | split row (char esep) | append $"($env.HOME)/.dotnet/tools" )

# ...and ddcoterm shims should take priority over everything
$env.PATH = ($env.PATH | split row (char esep) | prepend $"($env.HOME)/.ddcoterm/overrides" )
$env.PATH = ($env.PATH | split row (char esep) | prepend $"($env.HOME)/.ddcoterm/bin" )

if (sys host | get name) == "Darwin" {
    # Include Intel Homebrew and other tools installed outside /opt/homebrew.
    $env.PATH = ($env.PATH | split row (char esep) | append "/usr/local/bin" )
}

if (sys host | get long_os_version) =~ "Linux" {
    $env.PATH = ($env.PATH | split row (char esep) | append "/snap/bin" )
}

$env.PATH = ($env.PATH | uniq)

# ─── END mirrored block ───

# Reilly's private env vars

try {
    open ~/dotfiles/private/env-vars.nuon | load-env
}
