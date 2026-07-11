# Nushell Config File

# ─── BEGIN mirrored block ───
# Keep in sync with zsh/zshrc and nu/env.nu (manual sync, no codegen)

alias lg = lazygit

def --env mkd [dir:string] { mkdir $dir; cd $dir }

# ─── END mirrored block ───

alias t = templater
alias sn = templater snippet
alias st = systemctl-tui
alias cr = cargo run
alias cb = cargo build
alias ltc = llm chat -t terse

def lt [ ...words] {
    let prompt = $words | str join ' '
    llm -t terse $prompt
}


def exists [executable] { not (which $executable | is-empty) }
def clip [] {
    let input = $in;

    match $nu.os-info.name {
      "linux" => ($input | xclip -sel clip),
      "macos" => ($input | pbcopy),
    }
}

# Commands for RPM (Reilly's Package Manager)

def publish-to-rpm [ path:string --help (-h) ] {
	rsync --progress $path potato-pi:/mnt/QNAP1/rpm/dropbox/
}

def os-arch-string [] {
    let os = match $nu.os-info.name {
      "linux" => "linux",
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
      "macos" => (unzip -o $zip_file_name),
    }
}

def --env presentation-mode [] {
  $env.PROMPT_COMMAND = { || "" }
  $env.PROMPT_COMMAND_RIGHT = { || "" }
}

def is-not-empty [] { ($in | length) >= 1 }

def is-sqlite-db [$path: path] {(open --raw $path | take 16) == ($"SQLite format 3(char -i 0)" | into binary)}

def in-dotnet-project [] { ls | where ($it.name | str ends-with .csproj) | is-not-empty }
def in-rust-project [] { ls | where name == Cargo.toml | is-not-empty }
def in-node-project [] { ls | where name == package.json | is-not-empty }
def in-go-project [] { ls | where name == go.mod | is-not-empty }

# def dl-music [ url:string ] {
#     cd /mnt/QNAP1/Downloads/Music;
#     sqlite3 downloadQueue.db $"insert into queue\(Url, Type\) values\('($url)', 'Audio'\);"
# }

# TODO: assign these to keybindings
def build-current-project [] {
  print "building current project...";
  if (in-dotnet-project) {
      dotnet build
  } else if (in-rust-project) {
      cargo build
  } else if (in-node-project) {
      npm run build # TODO: figure out a way to pick+cache an NPM script per directory
  } else {
      'Not sure how to build in this folder.'
  }
}

def run-current-project [] {
  print "running current project...";
  if (in-rust-project) {
      cargo run
  } else if (in-dotnet-project) {
      dotnet run
  } else if (in-node-project)  {
      npm run start
  } else {
      'Not sure how to run code in this folder.'
  }
}

def wat [...split_name:string] {
    tldr ...$split_name

    let name = ($split_name | str join " ");

    let md = $"($name).md"

    cd ~/dotfiles/notes
    let notePath = ($nu.home-dir | path join $"dotfiles/notes/($name).md");

    if ( $notePath | path exists ) {
        echo "📘 Local Notes 📘"
        echo ""

        if (exists mdcat) {
            mdcat $notePath
        } else if (exists glow) {
            glow $notePath
        } else {
            cat $notePath
        }
    }
}

$env.config.table.mode = "rounded"
$env.config.table.header_on_separator = true
$env.config.table.padding = {left: 0, right: 0}
$env.config.table.index_mode = "always"

$env.config.history.file_format = "sqlite"

$env.config.footer_mode = 4

$env.config.shell_integration.osc133 = true

$env.config.color_config.separator = "dark_gray"
