# Nushell Environment Config File

$env.EDITOR = "micro"
$env.RUST_BACKTRACE = 1

if (sys host | get hostname) == "framework-fry" {
    # $env.DOTNET_ROOT = "/home/linuxbrew/.linuxbrew/opt/dotnet/libexec"

    $env.DOTNET_ROOT = "/home/reilly/.dotnet/"
}

# *nix locale
$env.LC_ALL = "en_US.UTF-8"

# To add entries to PATH (on Windows you might use Path), you can use the following pattern:
# $env.PATH = ($env.PATH | split row (char esep) | prepend '/some/path')

# macOS ARM64 / Apple Silicon
if (sys host | get name) == "Darwin" {
    $env.PATH = ($env.PATH | split row (char esep) | prepend '/opt/homebrew/bin')
}

if (sys host | get long_os_version) =~ "Linux" {
    # for https://github.com/arquivolta/wsl-use-windows-openssh
    $env.PATH = ($env.PATH | split row (char esep) | prepend /usr/lib/wsl-ssh )

    # prepend linuxbrew so it takes priority over Windows paths on WSL
    $env.PATH = ($env.PATH | split row (char esep) | prepend /home/linuxbrew/.linuxbrew/bin)

    $env.PATH = ($env.PATH | split row (char esep) | append "/snap/bin" )
}

# ...but ~/bin should take priority over linuxbrew
$env.PATH = ($env.PATH | split row (char esep) | prepend $"($env.HOME)/bin" )

# ...and ddcoterm shims should take priority over everything
$env.PATH = ($env.PATH | split row (char esep) | prepend $"($env.HOME)/.ddcoterm/overrides" )
$env.PATH = ($env.PATH | split row (char esep) | prepend $"($env.HOME)/.ddcoterm/bin" )

$env.PATH = ($env.PATH | split row (char esep) | append $"($env.HOME)/.cargo/bin" )

if (sys host | get name) == "Darwin" {
    # useful on macOS (TODO: I don't remember why, is this necessary?)
    $env.PATH = ($env.PATH | split row (char esep) | append "/usr/local/bin" )
}

# for pipx
$env.PATH = ($env.PATH | split row (char esep) | append $"($env.HOME)/.local/bin" )

$env.PATH = ($env.PATH | split row (char esep) | append $"($env.HOME)/.dotnet" )

# Reilly's private env vars

try {
    open ~/dotfiles/private/env-vars.nuon | load-env
}
