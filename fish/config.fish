set PATH /Users/reillywood/.npm-global/bin $PATH
set PATH $HOME/.cargo/bin $PATH
set PATH $HOME/.jenv/bin $PATH
status --is-interactive; and source (jenv init -|psub)
bind \cx\ce edit_command_buffer

switch (uname)
case Linux
    echo Hi Tux! This is config.fish speaking
case Darwin
    # Make VS Code the default editor
    set -Ux EDITOR code --wait --new-window
    set -Ux VISUAL code --wait --new-window
end