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

# ─── END mirrored block ───

# ...and ddcoterm shims should take priority over everything
$env.PATH = ($env.PATH | split row (char esep) | prepend $"($env.HOME)/.ddcoterm/overrides" )
$env.PATH = ($env.PATH | split row (char esep) | prepend $"($env.HOME)/.ddcoterm/bin" )

if (sys host | get name) == "Darwin" {
    # useful on macOS (TODO: I don't remember why, is this necessary?)
    $env.PATH = ($env.PATH | split row (char esep) | append "/usr/local/bin" )
}

if (sys host | get long_os_version) =~ "Linux" {
    $env.PATH = ($env.PATH | split row (char esep) | append "/snap/bin" )
}

# Reilly's private env vars

try {
    open ~/dotfiles/private/env-vars.nuon | load-env
}
