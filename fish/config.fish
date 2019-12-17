set PATH /Users/reillywood/.npm-global/bin $PATH
set PATH $HOME/.cargo/bin $PATH

# Bash binding for editing current buffer in VS Code
# Ideally this would use the builtin edit_command_buffer but it
# chokes on arguments to `code`
bind \cx\ce edit_command_buffer_in_vs_code

# OS-specific stuff
switch (uname)
    case Linux
    #     echo Hi Tux! This is config.fish speaking
       set -Ux VISUAL /usr/bin/vim
    case Darwin
#     echo Hi macOS! This is config.fish speaking
        set PATH $HOME/.jenv/bin $PATH
        status --is-interactive; and source (jenv init -|psub)
        # Make VS Code the default editor
        set -Ux VISUAL code --wait --new-window
end