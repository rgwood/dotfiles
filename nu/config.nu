# Nushell Config File

alias lg = lazygit
alias sn = templater snippet

def exists [executable] { not (which $executable | empty?) }
def clip [] {
    let input = $in;

    if exists clip.exe {
        $input | clip.exe
    } else {
        $input | xclip -sel clip
    }
}

# Commands for RPM (Reilly's Package Manager)

def publish-to-rpm [ path:string --help (-h) ] {
	if $nu.os-info.name == "windows" {
		# christ I wish rsync was available on Windows
		scp $path potato-pi:/mnt/QNAP1/rpm/dropbox/
	} else {
		rsync --progress $path potato-pi:/mnt/QNAP1/rpm/dropbox/
	}
}

def os-arch-string [] {
    let os = if $nu.os-info.name == "linux" {
        "linux"
    } else if $nu.os-info.name == "windows" {
        "win"
    } else if $nu.os-info.name == "macos" {
        "mac"
    } else {
        error make {msg: "unsupported os"}
    }

    let arch = if $nu.os-info.arch == "x86_64" {
        "x64"
    } else if $nu.os-info.arch == "aarch64" {
        "arm64"
    } else {
        error make {msg: "unsupported arch"}
    }

    $"($os)-($arch)"
}

def upgrade-rpm [] {
    cd ~/bin;

    let zip_file_name = $"(os-arch-string).zip"

    curl --location -O $"https://rpm.reillywood.com/($zip_file_name)"

    if $nu.os-info.name == "linux" {
        unzip -o $zip_file_name
    } else if $nu.os-info.name == "windows" {
        7z x -aoa $zip_file_name
    } else if $nu.os-info.name == "macos" {
        unzip -o $zip_file_name
    }
}

def-env presentation-mode [] {
  let-env PROMPT_COMMAND = { "" }
  let-env PROMPT_COMMAND_RIGHT = { "" }
}

def-env mkd [dir:string] { mkdir $dir; cd $dir }
def is-not-empty [] { ($in | length) >= 1 }

def is-sqlite-db [$path: path] {(open --raw $path | take 16) == ($"SQLite format 3(char -i 0)" | into binary)}

def in-dotnet-project [] { ls | where ($it.name | str ends-with .csproj) | is-not-empty }
def in-rust-project [] { ls | where name == Cargo.toml | is-not-empty }
def in-node-project [] { ls | where name == package.json | is-not-empty }
def in-go-project [] { ls | where name == go.mod | is-not-empty }

# A wrapper to fix `code ~/foo` on Windows (bug where that opens a new file named foo)
# TODO: this is buggy, doesn't work for individual files. also doesn't handle -n etc
# def code [path: string, ...] {
#     cd $path
#     ^code .
# }

def start [path] {
  # TODO handle WSL
  if $nu.os-info.name == "windows" {
    ^start $path
  } else if $nu.os-info.name == "macos" {
    ^open $path
  } else {
    xdg-open $path
  }
}

def dl-music [ url:string ] {
    cd /mnt/QNAP1/Downloads/Music;
    sqlite3 downloadQueue.db $"insert into queue\(Url, Type\) values\('($url)', 'Audio'\);"
}

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
  if in-rust-project {
      cargo run
  } else if in-dotnet-project {
      dotnet run
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

# for more information on themes see
# https://www.nushell.sh/book/coloring_and_theming.html
let default_theme = {
    # color for nushell primitives
    separator: white
    leading_trailing_space_bg: { attr: n } # no fg, no bg, attr none effectively turns this off
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
let-env config = {
  filesize_metric: false
  table_mode: rounded # basic, compact, compact_double, light, thin, with_love, rounded, reinforced, heavy, none, other
  use_ls_colors: true
  rm_always_trash: false
  color_config: $default_theme
  use_grid_icons: true
  footer_mode: "25" # always, never, number_of_rows, auto
  quick_completions: true  # set this to false to prevent auto-selecting completions when only one remains
  partial_completions: true  # set this to false to prevent partial filling of the prompt
  completion_algorithm: "prefix"  # prefix, fuzzy
  float_precision: 2
  buffer_editor: "micro" # command that will be used to edit the current line buffer with ctrl+o, if unset fallback to $env.EDITOR and $env.VISUAL
  use_ansi_coloring: true
  filesize_format: "auto" # b, kb, kib, mb, mib, gb, gib, tb, tib, pb, pib, eb, eib, zb, zib, auto
  edit_mode: emacs # emacs, vi
  max_history_size: 10000 # Session has to be reloaded for this to take effect
  sync_history_on_enter: true # Enable to share the history between multiple sessions, else you have to close the session to persist history to file
  shell_integration: true # enables terminal markers and a workaround to arrow keys stop working issue
  cd_with_abbreviations: false # set to true to allow you to do things like cd s/o/f and nushell expand it to cd some/other/folder
  case_sensitive_completions: false # set to true to enable case-sensitive completions

  hooks: {
    pre_prompt: [{
      $nothing  # replace with source code to run before the prompt is shown
    }]
    pre_execution: [{
      $nothing  # replace with source code to run before the repl input is run
    }]
    env_change: {
      PWD: [{|before, after|
        $nothing  # replace with source code to run if the PWD environment is different since the last repl input
      }]
    }
  }
  menus: [
      # Configuration for default nushell menus
      # Note the lack of souce parameter
      {
        name: completion_menu
        only_buffer_difference: false
        marker: "| "
        type: {
            layout: columnar
            columns: 4
            col_width: 20   # Optional value. If missing all the screen width is used to calculate column width
            col_padding: 2
        }
        style: {
            text: green
            selected_text: green_reverse
            description_text: yellow
        }
      }
      {
        name: history_menu
        only_buffer_difference: true
        marker: "? "
        type: {
            layout: list
            page_size: 10
        }
        style: {
            text: green
            selected_text: green_reverse
            description_text: yellow
        }
      }
      {
        name: help_menu
        only_buffer_difference: true
        marker: "? "
        type: {
            layout: description
            columns: 4
            col_width: 20   # Optional value. If missing all the screen width is used to calculate column width
            col_padding: 2
            selection_rows: 4
            description_rows: 10
        }
        style: {
            text: green
            selected_text: green_reverse
            description_text: yellow
        }
      }
      # Example of extra menus created using a nushell source
      # Use the source field to create a list of records that populates
      # the menu
      {
        name: commands_menu
        only_buffer_difference: false
        marker: "# "
        type: {
            layout: columnar
            columns: 4
            col_width: 20
            col_padding: 2
        }
        style: {
            text: green
            selected_text: green_reverse
            description_text: yellow
        }
        source: { |buffer, position|
            $nu.scope.commands
            | where command =~ $buffer
            | each { |it| {value: $it.command description: $it.usage} }
        }
      }
      {
        name: vars_menu
        only_buffer_difference: true
        marker: "# "
        type: {
            layout: list
            page_size: 10
        }
        style: {
            text: green
            selected_text: green_reverse
            description_text: yellow
        }
        source: { |buffer, position|
            $nu.scope.vars
            | where name =~ $buffer
            | sort-by name
            | each { |it| {value: $it.name description: $it.type} }
        }
      }
      {
        name: commands_with_description
        only_buffer_difference: true
        marker: "# "
        type: {
            layout: description
            columns: 4
            col_width: 20
            col_padding: 2
            selection_rows: 4
            description_rows: 10
        }
        style: {
            text: green
            selected_text: green_reverse
            description_text: yellow
        }
        source: { |buffer, position|
            $nu.scope.commands
            | where command =~ $buffer
            | each { |it| {value: $it.command description: $it.usage} }
        }
      }
  ]
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
      keycode: char_r
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
      keycode: enter
      mode: emacs
      event: { send: executehostcommand, cmd: "run-current-project" }
    }
    {
      name: run
      modifier: alt
      keycode: enter
      mode: emacs
      event: { send: executehostcommand, cmd: "run-current-project" }
    }
    # Keybindings used to trigger the user defined menus
    {
      name: commands_menu
      modifier: control
      keycode: char_t
      mode: [emacs, vi_normal, vi_insert]
      event: { send: menu name: commands_menu }
    }
    {
      name: vars_menu
      modifier: control
      keycode: char_y
      mode: [emacs, vi_normal, vi_insert]
      event: { send: menu name: vars_menu }
    }
    {
      name: commands_with_description
      modifier: control
      keycode: char_u
      mode: [emacs, vi_normal, vi_insert]
      event: { send: menu name: commands_with_description }
    }
  ]
}
