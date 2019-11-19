set PATH /Users/reillywood/.npm-global/bin $PATH
set PATH $HOME/.cargo/bin $PATH

# Bash binding for editing current buffer in VS Code
# Ideally this would use the builtin edit_command_buffer but it
# chokes on arguments to `code`
bind \cx\ce edit_command_buffer_in_vs_code

# Make VS Code the default editor
set -Ux EDITOR code --wait --new-window
set -Ux VISUAL code --wait --new-window

# OS-specific stuff
switch (uname)
    # case Linux
    #     echo Hi Tux! This is config.fish speaking
    case Darwin
#     echo Hi macOS! This is config.fish speaking
        set PATH $HOME/.jenv/bin $PATH
        status --is-interactive; and source (jenv init -|psub)
end