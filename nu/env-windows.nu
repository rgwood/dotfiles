# Nushell Environment Config File

$env.EDITOR = "/usr/bin/micro"
$env.RUST_BACKTRACE = 1

if (sys | get host.hostname) == "framework-fry" {
    # $env.DOTNET_ROOT = "/home/linuxbrew/.linuxbrew/opt/dotnet/libexec"

    $env.DOTNET_ROOT = "/home/reilly/.dotnet/"
}


def create_left_prompt [] {
    mut home = ""
    try {
        if $nu.os-info.name == "windows" {
            $home = $env.USERPROFILE
        } else {
            $home = $env.HOME
        }
    }

    let dir = ([
        ($env.PWD | str substring 0..($home | str length) | str replace $home "~"),
        ($env.PWD | str substring ($home | str length)..)
    ] | str join)

    let path_segment = if (is-admin) {
        $"(ansi red_bold)($dir)"
    } else {
        $"(ansi green_bold)($dir)"
    }

    $path_segment
}

def create_right_prompt [] {
    let time_segment = ([
        (date now | format date '%m/%d/%Y %r')
    ] | str join)

    $time_segment
}

# Use nushell functions to define your right and left prompt
$env.PROMPT_COMMAND = {|| create_left_prompt }
$env.PROMPT_COMMAND_RIGHT = {|| create_right_prompt }

# The prompt indicators are environmental variables that represent
# the state of the prompt
$env.PROMPT_INDICATOR = {|| "> " }
$env.PROMPT_INDICATOR_VI_INSERT = {|| ": " }
$env.PROMPT_INDICATOR_VI_NORMAL = {|| "> " }
$env.PROMPT_MULTILINE_INDICATOR = {|| "::: " }

# Specifies how environment variables are:
# - converted from a string to a value on Nushell startup (from_string)
# - converted from a value back to a string when running external commands (to_string)
# Note: The conversions happen *after* config.nu is loaded
$env.ENV_CONVERSIONS = {
  "PATH": {
    from_string: { |s| $s | split row (char esep) | path expand -n }
    to_string: { |v| $v | path expand -n | str join (char esep) }
  }
  "Path": {
    from_string: { |s| $s | split row (char esep) | path expand -n }
    to_string: { |v| $v | path expand -n | str join (char esep) }
  }
}

# Directories to search for scripts when calling source or use
#
# By default, <nushell-config-dir>/scripts is added
$env.NU_LIB_DIRS = [
    ($nu.config-path | path dirname | path join 'scripts')
]

# Directories to search for plugin binaries when calling register
#
# By default, <nushell-config-dir>/plugins is added
$env.NU_PLUGIN_DIRS = [
    ($nu.config-path | path dirname | path join 'plugins')
]

# *nix locale
$env.LC_ALL = "en_US.UTF-8"

# To add entries to PATH (on Windows you might use Path), you can use the following pattern:
# $env.PATH = ($env.PATH | split row (char esep) | prepend '/some/path')

# for https://github.com/arquivolta/wsl-use-windows-openssh
# $env.PATH = ($env.PATH | split row (char esep) | prepend /usr/lib/wsl-ssh )

# macOS ARM64 / Apple Silicon
# $env.PATH = ($env.PATH | split row (char esep) | prepend '/opt/homebrew/bin')

# prepend linuxbrew so it takes priority over Windows paths on WSL
# $env.PATH = ($env.PATH | split row (char esep) | prepend /home/linuxbrew/.linuxbrew/bin)

# $env.PATH = ($env.PATH | split row (char esep) | append $"($env.HOME)/bin" )
# $env.PATH = ($env.PATH | split row (char esep) | append $"($env.HOME)/github/nushell/target/release" )
# $env.PATH = ($env.PATH | split row (char esep) | append $"($env.HOME)/github/nushell/target/debug" )
# $env.PATH = ($env.PATH | split row (char esep) | append $"($env.HOME)/.cargo/bin" )
# $env.PATH = ($env.PATH | split row (char esep) | append "/snap/bin" )
# useful on macOS
# $env.PATH = ($env.PATH | split row (char esep) | append "/usr/local/bin" )

# $env.PATH = ($env.PATH | split row (char esep) | append $"($env.HOME)/.dotnet" )

# Reilly's private env vars

try {
    open ~/dotfiles/private/env-vars.nuon | load-env
}
