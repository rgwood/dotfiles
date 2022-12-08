# Nushell Config File

alias lg = lazygit
alias sn = templater snippet

def exists [executable] { not (which $executable | is-empty) }
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


alias rpm-upgrade = upgrade-rpm

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
let dark_theme = {
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
    shape_directory: cyan
    shape_globpattern: cyan_bold
    shape_variable: purple
    shape_flag: blue_bold
    shape_custom: green
    shape_nothing: light_cyan
    shape_matching_brackets: { attr: u }
}

let light_theme = {
    # color for nushell primitives
    separator: dark_gray
    leading_trailing_space_bg: { attr: n } # no fg, no bg, attr none effectively turns this off
    header: green_bold
    empty: blue
    bool: dark_gray
    int: dark_gray
    filesize: dark_gray
    duration: dark_gray
    date: dark_gray
    range: dark_gray
    float: dark_gray
    string: dark_gray
    nothing: dark_gray
    binary: dark_gray
    cellpath: dark_gray
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
    shape_directory: cyan
    shape_globpattern: cyan_bold
    shape_variable: purple
    shape_flag: blue_bold
    shape_custom: green
    shape_nothing: light_cyan
    shape_matching_brackets: { attr: u }
}

# External completer example
# let carapace_completer = {|spans| 
#     carapace $spans.0 nushell $spans | from json
# }


# The default config record. This is where much of your global configuration is setup.
let-env config = {
  ls: {
    use_ls_colors: true # use the LS_COLORS environment variable to colorize output
    clickable_links: true # enable or disable clickable links. Your terminal has to support links.
  }
  rm: {
    always_trash: false # always act as if -t was given. Can be overridden with -p
  }
  cd: {
    abbreviations: true # allows `cd s/o/f` to expand to `cd some/other/folder`
  }
  table: {
    mode: rounded # basic, compact, compact_double, light, thin, with_love, rounded, reinforced, heavy, none, other
    index_mode: always # "always" show indexes, "never" show indexes, "auto" = show indexes when a table has "index" column
    trim: {
      methodology: wrapping # wrapping or truncating
      wrapping_try_keep_words: true # A strategy used by the 'wrapping' methodology
      truncating_suffix: "..." # A suffix used by the 'truncating' methodology
    }
  }
  history: {
    max_size: 10000 # Session has to be reloaded for this to take effect
    sync_on_enter: true # Enable to share history between multiple sessions, else you have to close the session to write history to file
    file_format: "sqlite" # "sqlite" or "plaintext"
  }
  completions: {
    case_sensitive: false # set to true to enable case-sensitive completions
    quick: true  # set this to false to prevent auto-selecting completions when only one remains
    partial: true  # set this to false to prevent partial filling of the prompt
    algorithm: "prefix"  # prefix or fuzzy
    external: {
      enable: true # set to false to prevent nushell looking into $env.PATH to find more suggestions, `false` recommended for WSL users as this look up my be very slow
      max_results: 100 # setting it lower can improve completion performance at the cost of omitting some options
      completer: null # check 'carapace_completer' above as an example
    }
  }
  filesize: {
    metric: true # true => KB, MB, GB (ISO standard), false => KiB, MiB, GiB (Windows standard)
    format: "auto" # b, kb, kib, mb, mib, gb, gib, tb, tib, pb, pib, eb, eib, zb, zib, auto
  }
  color_config: $dark_theme   # if you want a light theme, replace `$dark_theme` to `$light_theme`
  use_grid_icons: true
  footer_mode: "25" # always, never, number_of_rows, auto
  float_precision: 2
  buffer_editor: "micro" # command that will be used to edit the current line buffer with ctrl+o, if unset fallback to $env.EDITOR and $env.VISUAL
  use_ansi_coloring: true
  edit_mode: emacs # emacs, vi
  shell_integration: true # enables terminal markers and a workaround to arrow keys stop working issue
  show_banner: true # true or false to enable or disable the banner
  render_right_prompt_on_last_line: false # true or false to enable or disable right prompt to be rendered on last line of the prompt.
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
    display_output: {
      if (term size).columns >= 100 { table -e } else { table }
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
      event: { send: menu name: history_menu }
    }
    {
      name: next_page
      modifier: control
      keycode: char_x
      mode: emacs
      event: { send: menupagenext }
    }
    {
      name: undo_or_previous_page
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
      modifier: alt
      keycode: char_o
      mode: [emacs, vi_normal, vi_insert]
      event: { send: menu name: vars_menu }
    }
    {
      name: commands_with_description
      modifier: control
      keycode: char_s
      mode: [emacs, vi_normal, vi_insert]
      event: { send: menu name: commands_with_description }
    }
  ]
}
