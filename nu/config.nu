# Nushell Config File

alias lg = lazygit

def-env mkd [dir:string] { mkdir $dir; cd $dir }

def any [] { length | $in >= 1 }

def in-dotnet-project [] { ls | where ($it.name | str ends-with .csproj) | any }
def in-rust-project [] { ls | where name == Cargo.toml | any }
def in-node-project [] { ls | where name == package.json | any }
def in-go-project [] { ls | where name == go.mod | any }

def build-current-project [] {
  if in-dotnet-project {
      dotnet build
  } else if in-rust-project {
      cargo build
  } else if in-node-project {
      npm run build # TODO: figure out a way to pick+cache an NPM script per directory
  } else {
      'Not sure how to build in this folder.'
  }
}

def run-current-project [] {
  if in-dotnet-project {
      dotnet run
  } else if in-rust-project {
      cargo run
  } else if in-node-project {
      npm run start
  } else {
      'Not sure how to run code in this folder.'
  }
}

def wat [...split_name:string] {
    tldr $split_name

    let name = ($split_name | str collect " ");

    let md = $"($name).md"

    let solarized = {
        "Black": "0x002b36",
        "DarkGray": "0x073642",
        "DarkGreen": "0x586e75",
        "DarkYellow": "0x657b83",
        "DarkBlue": "0x839496",
        "DarkCyan": "0x93a1a1",
        "Gray": "0xeee8d5",
        "White": "0xfdf6e3",
        "Red": "0xdc322f",
        "DarkRed": "0xcb4b16",
        "Yellow": "0xb58900",
        "Green": "0x859900",
        "Cyan": "0x2aa198",
        "Blue": "0x268bd2",
        "Magenta": "0x6c71c4",
        "DarkMagenta": "0xd33682"
    }

    cd ~/dotfiles/notes
    let notePath = ($nu.home-path | path join $"dotfiles/notes/($name).md");

    if ( $notePath | path exists ) {

        # echo "Local Notes" | ansi gradient --fgstart 0x40c9ff --fgend 0xe81cff
        # echo "Local Notes" | ansi gradient --fgstart $solarized.Blue --fgend $solarized.Magenta
        # echo "Local Notes" | ansi gradient --fgstart $solarized.Cyan --fgend $solarized.Magenta
        # echo "Local Notes" | ansi gradient --fgstart $solarized.Blue --fgend $solarized.DarkMagenta
        # echo "Local Notes:" | ansi gradient --fgstart $solarized.Blue --fgend $solarized.Yellow

        echo "📘 Local Notes 📘" | ansi gradient --fgstart $solarized.Blue --fgend $solarized.Green

        echo ""
        mdcat $notePath
    }
}


# from https://github.com/nushell/nu_scripts/tree/main/custom-completions/npm
module npm-completions {
  export extern "npm" [
    command: string@"nu-complete npm"
  ]
  def "nu-complete npm" [] {
    ^npm -l
    |lines
    |find 'Run "'
    |str trim
    |split column -c ' '
    |get column4
    |str find-replace '"' ''
  }

  def "nu-complete npm run" [] {
    open ./package.json
    |get scripts
    |columns
  }
  export extern "npm run" [
    command: string@"nu-complete npm run"
    --workspace(-w)
    --include-workspace-root
    --if-present
    --ignore-scripts
    --script-shell
  ]
}

use npm-completions *

def create_left_prompt [] {
    let path_segment = ($env.PWD)

    $path_segment
}

def create_right_prompt [] {
    let time_segment = ([
        (date now | date format '%m/%d/%Y %r')
    ] | str collect)

    $time_segment
}

# Use nushell functions to define your right and left prompt
let-env PROMPT_COMMAND = { create_left_prompt }
let-env PROMPT_COMMAND_RIGHT = { create_right_prompt }

# The prompt indicators are environmental variables that represent
# the state of the prompt
let-env PROMPT_INDICATOR = "〉"
let-env PROMPT_INDICATOR_VI_INSERT = ": "
let-env PROMPT_INDICATOR_VI_NORMAL = "〉"
let-env PROMPT_MULTILINE_INDICATOR = "::: "

# Specifies how environment variables are:
# - converted from a string to a value on Nushell startup (from_string)
# - converted from a value back to a string when running extrnal commands (to_string)
# Note: The conversions happen *after* config.nu is loaded
let-env ENV_CONVERSIONS = {
  "PATH": {
    from_string: { |s| $s | split row (char esep) }
    to_string: { |v| $v | str collect (char esep) }
  }
  "Path": {
    from_string: { |s| $s | split row (char esep) }
    to_string: { |v| $v | str collect (char esep) }
  }
}

# Directories to search for scripts when calling source or use
#
# By default, <nushell-config-dir>/scripts is added
let-env NU_LIB_DIRS = [
    ($nu.config-path | path dirname | path join 'scripts')
]

# Directories to search for plugin binaries when calling register
#
# By default, <nushell-config-dir>/plugins is added
let-env NU_PLUGIN_DIRS = [
    ($nu.config-path | path dirname | path join 'plugins')
]

# Custom completions for external commands (those outside of Nushell)
# Each completions has two parts: the form of the external command, including its flags and parameters
# and a helper command that knows how to complete values for those flags and parameters
#
# This is a simplified version of completions for git branches and git remotes
def "nu-complete git branches" [] {
  ^git branch | lines | each { |line| $line | str find-replace '\* ' '' | str trim }
}

def "nu-complete git remotes" [] {
  ^git remote | lines | each { |line| $line | str trim }
}

extern "git checkout" [
  branch?: string@"nu-complete git branches" # name of the branch to checkout
  -b: string                                 # create and checkout a new branch
  -B: string                                 # create/reset and checkout a branch
  -l                                         # create reflog for new branch
  --guess                                    # second guess 'git checkout <no-such-branch>' (default)
  --overlay                                  # use overlay mode (default)
  --quiet(-q)                                # suppress progress reporting
  --recurse-submodules: string               # control recursive updating of submodules
  --progress                                 # force progress reporting
  --merge(-m)                                # perform a 3-way merge with the new branch
  --conflict: string                         # conflict style (merge or diff3)
  --detach(-d)                               # detach HEAD at named commit
  --track(-t)                                # set upstream info for new branch
  --force(-f)                                # force checkout (throw away local modifications)
  --orphan: string                           # new unparented branch
  --overwrite-ignore                         # update ignored files (default)
  --ignore-other-worktrees                   # do not check if another worktree is holding the given ref
  --ours(-2)                                 # checkout our version for unmerged files
  --theirs(-3)                               # checkout their version for unmerged files
  --patch(-p)                                # select hunks interactively
  --ignore-skip-worktree-bits                # do not limit pathspecs to sparse entries only
  --pathspec-from-file: string               # read pathspec from file
]

extern "git push" [
  remote?: string@"nu-complete git remotes", # the name of the remote
  refspec?: string@"nu-complete git branches"# the branch / refspec
  --verbose(-v)                              # be more verbose
  --quiet(-q)                                # be more quiet
  --repo: string                             # repository
  --all                                      # push all refs
  --mirror                                   # mirror all refs
  --delete(-d)                               # delete refs
  --tags                                     # push tags (can't be used with --all or --mirror)
  --dry-run(-n)                              # dry run
  --porcelain                                # machine-readable output
  --force(-f)                                # force updates
  --force-with-lease: string                 # require old value of ref to be at this value
  --recurse-submodules: string               # control recursive pushing of submodules
  --thin                                     # use thin pack
  --receive-pack: string                     # receive pack program
  --exec: string                             # receive pack program
  --set-upstream(-u)                         # set upstream for git pull/status
  --progress                                 # force progress reporting
  --prune                                    # prune locally removed refs
  --no-verify                                # bypass pre-push hook
  --follow-tags                              # push missing but relevant tags
  --signed: string                           # GPG sign the push
  --atomic                                   # request atomic transaction on remote side
  --push-option(-o): string                  # option to transmit
  --ipv4(-4)                                 # use IPv4 addresses only
  --ipv6(-6)                                 # use IPv6 addresses only
]

# for more information on themes see
# https://github.com/nushell/nushell/blob/main/docs/How_To_Coloring_and_Theming.md
let default_theme = {
    # color for nushell primitives
    separator: white
    leading_trailing_space_bg: { attr: n } # no fg, no bg, attr non effectively turns this off
    header: green_bold
    empty: blue
    bool: white
    int: white
    filesize: white
    duration: white
    date: white
    range: white
    float: white
    string: white
    nothing: white
    binary: white
    cellpath: white
    row_index: green_bold
    record: white
    list: white
    block: white
    hints: dark_gray

    # shapes are used to change the cli syntax highlighting
    shape_garbage: { fg: "#FFFFFF" bg: "#FF0000" attr: b}
    shape_binary: purple_bold
    shape_bool: light_cyan
    shape_int: purple_bold
    shape_float: purple_bold
    shape_range: yellow_bold
    shape_internalcall: cyan_bold
    shape_external: cyan
    shape_externalarg: green_bold
    shape_literal: blue
    shape_operator: yellow
    shape_signature: green_bold
    shape_string: green
    shape_string_interpolation: cyan_bold
    shape_datetime: cyan_bold
    shape_list: cyan_bold
    shape_table: blue_bold
    shape_record: cyan_bold
    shape_block: blue_bold
    shape_filepath: cyan
    shape_globpattern: cyan_bold
    shape_variable: purple
    shape_flag: blue_bold
    shape_custom: green
    shape_nothing: light_cyan
}

# The default config record. This is where much of your global configuration is setup.
let $config = {
  filesize_metric: false
  table_mode: rounded # basic, compact, compact_double, light, thin, with_love, rounded, reinforced, heavy, none, other
  use_ls_colors: true
  rm_always_trash: false
  color_config: $default_theme
  use_grid_icons: true
  footer_mode: "25" # always, never, number_of_rows, auto
  quick_completions: true  # set this to false to prevent auto-selecting completions when only one remains
  partial_completions: true  # set this to false to prevent partial filling of the prompt
  animate_prompt: false # redraw the prompt every second
  float_precision: 2
  use_ansi_coloring: true
  filesize_format: "auto" # b, kb, kib, mb, mib, gb, gib, tb, tib, pb, pib, eb, eib, zb, zib, auto
  edit_mode: emacs # emacs, vi
  max_history_size: 10000
  menu_config: {
    columns: 4
    col_width: 20   # Optional value. If missing all the screen width is used to calculate column width
    col_padding: 2
    text_style: green
    selected_text_style: green_reverse
    marker: "| "
  }
  history_config: {
    page_size: 10
    selector: "!"
    text_style: green
    selected_text_style: green_reverse
    marker: "? "
  }
  keybindings: [
    {
      name: completion_menu
      modifier: none
      keycode: tab
      mode: emacs # Options: emacs vi_normal vi_insert
      event: {
        until: [
          { send: menu name: completion_menu }
          { send: menunext }
        ]
      }
    }
    {
      name: completion_previous
      modifier: shift
      keycode: backtab
      mode: [emacs, vi_normal, vi_insert] # Note: You can add the same keybinding to all modes by using a list
      event: { send: menuprevious }
    }
    {
      name: history_menu
      modifier: control
      keycode: char_x
      mode: emacs
      event: {
        until: [
          { send: menu name: history_menu }
          { send: menupagenext }
        ]
      }
    }
    {
      name: history_previous
      modifier: control
      keycode: char_z
      mode: emacs
      event: {
        until: [
          { send: menupageprevious }
          { edit: undo }
        ]
      }
    }
    {
      name: reload_config
      modifier: none
      keycode: f5
      mode: emacs
      event: {
        send: executehostcommand,
        cmd: $"source '($nu.config-path)'"
      }
    }
    {
      name: build
      modifier: control
      keycode: char_b
      mode: emacs
      event: {
        send: executehostcommand,
        cmd: "build-current-project"
      }
    }
    {
      name: run
      modifier: control
      keycode: char_r
      mode: emacs
      event: {
        send: executehostcommand,
        cmd: "run-current-project"
      }
    }
  ]
}
