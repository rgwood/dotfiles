# Nushell Config File

# ─── BEGIN mirrored block ───
# Keep in sync with zsh/zshrc and nu/env.nu (manual sync, no codegen)

def --env mkd [dir:string] { mkdir $dir; cd $dir }

# ─── END mirrored block ───

alias t = templater
alias sn = templater snippet
alias ltc = llm chat -t terse

def lt [ ...words] {
    let prompt = $words | str join ' '
    llm -t terse $prompt
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

$env.config.table.mode = "rounded"
$env.config.table.header_on_separator = true
$env.config.table.padding = {left: 0, right: 0}
$env.config.table.index_mode = "always"

$env.config.history.file_format = "sqlite"

$env.config.footer_mode = 4

$env.config.shell_integration.osc133 = true

$env.config.color_config.separator = "dark_gray"
