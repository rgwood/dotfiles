# Nushell Config File

alias t = templater
alias sn = templater snippet
alias lg = lazygit
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
      "windows" => ($input | clip.exe),
      "macos" => ($input | pbcopy),
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

def parse-timestamp [ts: string] {
    let parts = ($ts | split row ":" | each { into int })
    match ($parts | length) {
        2 => { ($parts.0 * 60) + $parts.1 }
        3 => { ($parts.0 * 3600) + ($parts.1 * 60) + $parts.2 }
        _ => { error make { msg: "invalid timestamp format" } }
    }
}

def trim [file: string, from: string, to: string] {
    let parts = $file | path parse
    let newFileName = $"($parts.stem)-trimmed.($parts.extension)"
    let duration = (parse-timestamp $to) - (parse-timestamp $from)
    ffmpeg -ss $from -t $duration -i $file -codec copy $newFileName
}

$env.config.table.mode = "rounded"
$env.config.table.header_on_separator = true
$env.config.table.padding = {left: 0, right: 0}
$env.config.table.index_mode = "always"

$env.config.history.file_format = "sqlite"

$env.config.footer_mode = 4

# Reilly: osc133 causes issues in Windows WezTerm (every keypress scrolls up)
$env.config.shell_integration.osc133 = false

$env.config.color_config.separator = "dark_gray"
