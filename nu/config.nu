# Nushell Config File

alias lg = lazygit
alias sn = templater snippet
alias st = systemctl-tui
alias cr = cargo run

def exists [executable] { not (which $executable | is-empty) }
def clip [] {
    let input = $in;

    if (exists clip.exe) {
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
    let os = match $nu.os-info.name {
      "linux" => "linux",
      "windows" => "win",
      "macos" => "mac",
      _ => (error make {msg: "unsupported os"})
    }

    let arch = match $nu.os-info.arch {
      "x86_64" => "x64",
      "aarch64" => "arm64",
      _ => (error make {msg: "unsupported arch"})
    }

    $"($os)-($arch)"
}

alias rpm-upgrade = upgrade-rpm

def upgrade-rpm [] {
    cd ~/bin;

    let zip_file_name = $"(os-arch-string).zip"

    curl --location -O $"https://rpm.reillywood.com/($zip_file_name)"

    match $nu.os-info.name {
      "linux" => (unzip -o $zip_file_name),
      "windows" => (7z x -aoa $zip_file_name),
      "macos" => (unzip -o $zip_file_name),
    }
}

def --env presentation-mode [] {
  $env.PROMPT_COMMAND = { || "" }
  $env.PROMPT_COMMAND_RIGHT = { || "" }
}

def --env mkd [dir:string] { mkdir $dir; cd $dir }
def is-not-empty [] { ($in | length) >= 1 }

def is-sqlite-db [$path: path] {(open --raw $path | take 16) == ($"SQLite format 3(char -i 0)" | into binary)}

def in-dotnet-project [] { ls | where ($it.name | str ends-with .csproj) | is-not-empty }
def in-rust-project [] { ls | where name == Cargo.toml | is-not-empty }
def in-node-project [] { ls | where name == package.json | is-not-empty }
def in-go-project [] { ls | where name == go.mod | is-not-empty }

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

def --env yz () {
  yazi --cwd-file=/tmp/yazi_cwd.txt
  let path = open /tmp/yazi_cwd.txt
  cd $path
}

def wat [...split_name:string] {
    tldr ...$split_name

    let name = ($split_name | str join " ");

    let md = $"($name).md"

    cd ~/dotfiles/notes
    let notePath = ($nu.home-path | path join $"dotfiles/notes/($name).md");

    if ( $notePath | path exists ) {
        echo "📘 Local Notes 📘"
        echo ""
        mdcat $notePath
    }
}

# For more information on defining custom themes, see
# https://www.nushell.sh/book/coloring_and_theming.html
# And here is the theme collection
# https://github.com/nushell/nu_scripts/tree/main/themes
let dark_theme = {
    # color for nushell primitives
    separator: blue
    leading_trailing_space_bg: { attr: n } # no fg, no bg, attr none effectively turns this off
    header: green_bold
    empty: blue
    # Closures can be used to choose colors for specific values.
    # The value (in this case, a bool) is piped into the closure.
    # eg) {|| if $in { 'light_cyan' } else { 'light_gray' } }
    bool: light_cyan
    int: white
    filesize: cyan
    duration: white
    date: purple
    range: white
    float: white
    string: white
    nothing: white
    binary: white
    cell-path: white
    row_index: green_bold
    record: white
    list: white
    block: white
    hints: dark_gray
    search_result: { bg: red fg: white }
    shape_and: purple_bold
    shape_binary: purple_bold
    shape_block: blue_bold
    shape_bool: light_cyan
    shape_closure: green_bold
    shape_custom: green
    shape_datetime: cyan_bold
    shape_directory: cyan
    shape_external: cyan
    shape_externalarg: green_bold
    shape_external_resolved: light_yellow_bold
    shape_filepath: cyan
    shape_flag: blue_bold
    shape_float: purple_bold
    # shapes are used to change the cli syntax highlighting
    shape_garbage: { fg: white bg: red attr: b}
    shape_globpattern: cyan_bold
    shape_int: purple_bold
    shape_internalcall: cyan_bold
    shape_keyword: cyan_bold
    shape_list: cyan_bold
    shape_literal: blue
    shape_match_pattern: green
    shape_matching_brackets: { attr: u }
    shape_nothing: light_cyan
    shape_operator: yellow
    shape_or: purple_bold
    shape_pipe: purple_bold
    shape_range: yellow_bold
    shape_record: cyan_bold
    shape_redirection: purple_bold
    shape_signature: green_bold
    shape_string: green
    shape_string_interpolation: cyan_bold
    shape_table: blue_bold
    shape_variable: purple
    shape_vardecl: purple
    shape_raw_string: light_purple
}

let light_theme = {
    # color for nushell primitives
    separator: dark_gray
    leading_trailing_space_bg: { attr: n } # no fg, no bg, attr none effectively turns this off
    header: green_bold
    empty: blue
    # Closures can be used to choose colors for specific values.
    # The value (in this case, a bool) is piped into the closure.
    # eg) {|| if $in { 'dark_cyan' } else { 'dark_gray' } }
    bool: dark_cyan
    int: dark_gray
    filesize: cyan_bold
    duration: dark_gray
    date: purple
    range: dark_gray
    float: dark_gray
    string: dark_gray
    nothing: dark_gray
    binary: dark_gray
    cell-path: dark_gray
    row_index: green_bold
    record: dark_gray
    list: dark_gray
    block: dark_gray
    hints: dark_gray
    search_result: { fg: white bg: red }
    shape_and: purple_bold
    shape_binary: purple_bold
    shape_block: blue_bold
    shape_bool: light_cyan
    shape_closure: green_bold
    shape_custom: green
    shape_datetime: cyan_bold
    shape_directory: cyan
    shape_external: cyan
    shape_externalarg: green_bold
    shape_external_resolved: light_purple_bold
    shape_filepath: cyan
    shape_flag: blue_bold
    shape_float: purple_bold
    # shapes are used to change the cli syntax highlighting
    shape_garbage: { fg: white bg: red attr: b}
    shape_globpattern: cyan_bold
    shape_int: purple_bold
    shape_internalcall: cyan_bold
    shape_keyword: cyan_bold
    shape_list: cyan_bold
    shape_literal: blue
    shape_match_pattern: green
    shape_matching_brackets: { attr: u }
    shape_nothing: light_cyan
    shape_operator: yellow
    shape_or: purple_bold
    shape_pipe: purple_bold
    shape_range: yellow_bold
    shape_record: cyan_bold
    shape_redirection: purple_bold
    shape_signature: green_bold
    shape_string: green
    shape_string_interpolation: cyan_bold
    shape_table: blue_bold
    shape_variable: purple
    shape_vardecl: purple
    shape_raw_string: light_purple
}

# External completer example
# let carapace_completer = {|spans|
#     carapace $spans.0 nushell $spans | from json
# }


# The default config record. This is where much of your global configuration is setup.
$env.config = {
    # true or false to enable or disable the welcome banner at startup
    show_banner: true

  ls: {
    use_ls_colors: true # use the LS_COLORS environment variable to colorize output
    clickable_links: true # enable or disable clickable links. Your terminal has to support links.
  }
  rm: {
    always_trash: false # always act as if -t was given. Can be overridden with -p
  }
  table: {
    mode: rounded # basic, compact, compact_double, light, thin, with_love, rounded, reinforced, heavy, none, other
    header_on_separator: true
    padding: {left: 0 right: 0}
    index_mode: always # "always" show indexes, "never" show indexes, "auto" = show indexes when a table has "index" column
    trim: {
      methodology: wrapping # wrapping or truncating
      wrapping_try_keep_words: true # A strategy used by the 'wrapping' methodology
      truncating_suffix: "..." # A suffix used by the 'truncating' methodology
    }
  }

  error_style: "fancy" # "fancy" or "plain" for screen reader-friendly error messages

  # datetime_format determines what a datetime rendered in the shell would look like.
  # Behavior without this configuration point will be to "humanize" the datetime display,
  # showing something like "a day ago."
  datetime_format: {
    normal: '%a, %d %b %Y %H:%M:%S %z'    # shows up in displays of variables or other datetime's outside of tables
    table: '%m/%d/%y %I:%M:%S%p'          # generally shows up in tabular outputs such as ls. commenting this out will change it to the default human readable datetime format
    }

  explore: {
    status_bar_background: { fg: "#1D1F21", bg: "#C4C9C6" },
    command_bar_text: { fg: "#C4C9C6" },
    highlight: { fg: "black", bg: "yellow" },
    status: {
        error: { fg: "white", bg: "red" },
        warn: {}
        info: {}
    },
    table: {
        split_line: { fg: "#404040" },
        selected_cell: { bg: light_blue },
        selected_row: {},
        selected_column: {},
    },
    try: {
      reactive: true,
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
    use_ls_colors: true # set this to true to enable file/path/directory completions using LS_COLORS
  }
  filesize: {
    metric: true # true => KB, MB, GB (ISO standard), false => KiB, MiB, GiB (Windows standard)
    format: "auto" # b, kb, kib, mb, mib, gb, gib, tb, tib, pb, pib, eb, eib, zb, zib, auto
  }
  cursor_shape: {
    emacs: block # block, underscore, line (line is the default)
    vi_insert: block # block, underscore, line (block is the default)
    vi_normal: underscore # block, underscore, line  (underscore is the default)
  }
  color_config: $dark_theme   # if you want a light theme, replace `$dark_theme` to `$light_theme`
  use_grid_icons: true
  # TODO: footer mode should specify number of terminal rows, not number of Nushell rows
  footer_mode: "4" # always, never, number_of_rows, auto
  float_precision: 2
  buffer_editor: "micro" # command that will be used to edit the current line buffer with ctrl+o, if unset fallback to $env.EDITOR and $env.VISUAL
  use_ansi_coloring: true
  edit_mode: emacs # emacs, vi
  shell_integration: {
    # osc2 abbreviates the path if in the home_dir, sets the tab/window title, shows the running command in the tab/window title
    osc2: true
    # osc7 is a way to communicate the path to the terminal, this is helpful for spawning new tabs in the same directory
    osc7: true
    # osc8 is also implemented as the deprecated setting ls.show_clickable_links, it shows clickable links in ls output if your terminal supports it. show_clickable_links is deprecated in favor of osc8
    osc8: true
    # osc9_9 is from ConEmu and is starting to get wider support. It's similar to osc7 in that it communicates the path to the terminal
    osc9_9: false
    # Reilly: osc133 causes issues in Windows WezTerm (every keypress scrolls up)
    # osc133 is several escapes invented by Final Term which include the supported ones below.
    # 133;A - Mark prompt start
    # 133;B - Mark prompt end
    # 133;C - Mark pre-execution
    # 133;D;exit - Mark execution finished with exit code
    # This is used to enable terminals to know where the prompt is, the command is, where the command finishes, and where the output of the command is
    osc133: false
    # osc633 is closely related to osc133 but only exists in visual studio code (vscode) and supports their shell integration features
    # 633;A - Mark prompt start
    # 633;B - Mark prompt end
    # 633;C - Mark pre-execution
    # 633;D;exit - Mark execution finished with exit code
    # 633;E - NOT IMPLEMENTED - Explicitly set the command line with an optional nonce
    # 633;P;Cwd=<path> - Mark the current working directory and communicate it to the terminal
    # and also helps with the run recent menu in vscode
    osc633: true
    # reset_application_mode is escape \x1b[?1l and was added to help ssh work better
    reset_application_mode: true
}
  render_right_prompt_on_last_line: false # true or false to enable or disable right prompt to be rendered on last line of the prompt.
    use_kitty_protocol: false # enables keyboard enhancement protocol implemented by kitty console, only if your terminal support this.
    highlight_resolved_externals: false # true enables highlighting of external commands in the repl resolved by which.
    recursion_limit: 50 # the maximum number of times nushell allows recursion before stopping it

    plugins: {} # Per-plugin configuration. See https://www.nushell.sh/contributor-book/plugins.html#configuration.

    plugin_gc: {
        # Configuration for plugin garbage collection
        default: {
            enabled: true # true to enable stopping of inactive plugins
            stop_after: 10sec # how long to wait after a plugin is inactive to stop it
        }
        plugins: {
            # alternate configuration for specific plugins, by name, for example:
            #
            # gstat: {
            #     enabled: false
            # }
        }
    }

    hooks: {
        pre_prompt: [{ null }] # run before the prompt is shown
        pre_execution: [{ null }] # run before the repl input is run
        env_change: {
            PWD: [{|before, after| null }] # run if the PWD environment is different since the last repl input
        }
        # display_output: "if (term size).columns >= 100 { table -e } else { table }" # run to display the output of a pipeline
        command_not_found: { null } # return an error message when a command is not found
    }
    menus: [
      # Configuration for default nushell menus
      # Note the lack of source parameter
      {
          name: completion_menu
          only_buffer_difference: false
          marker: "| "
          type: {
              layout: columnar
              columns: 4
              col_width: 20     # Optional value. If missing all the screen width is used to calculate column width
              col_padding: 2
          }
          style: {
              text: green
              selected_text: { attr: r }
              description_text: yellow
              match_text: { attr: u }
              selected_match_text: { attr: ur }
          }
      }
      {
          name: ide_completion_menu
          only_buffer_difference: false
          marker: "| "
          type: {
              layout: ide
              min_completion_width: 0,
              max_completion_width: 50,
              max_completion_height: 10, # will be limited by the available lines in the terminal
              padding: 0,
              border: true,
              cursor_offset: 0,
              description_mode: "prefer_right"
              min_description_width: 0
              max_description_width: 50
              max_description_height: 10
              description_offset: 1
              # If true, the cursor pos will be corrected, so the suggestions match up with the typed text
              #
              # C:\> str
              #      str join
              #      str trim
              #      str split
              correct_cursor_pos: false
          }
          style: {
              text: green
              selected_text: { attr: r }
              description_text: yellow
              match_text: { attr: u }
              selected_match_text: { attr: ur }
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
              col_width: 20     # Optional value. If missing all the screen width is used to calculate column width
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

module openai {

  export def ask [question:string] {
    let key = $env.R_OPENAPI_KEY
    let body = {
      model: "gpt-3.5-turbo",
      messages: [{"role": "user", content: $question}]
    }

    let result = (http post -t 'application/json' -H ["Authorization" $"Bearer ($key)"] https://api.openai.com/v1/chat/completions $body)

    $result.choices.message.0.content
  }

}

use openai;