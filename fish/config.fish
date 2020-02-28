set PATH $HOME/.npm-global/bin $PATH
set PATH $HOME/.cargo/bin $PATH
# dotnet puts ~/.dotnet/tools in the path but Fish doesn't expand the tilde
set PATH $HOME/.dotnet/tools $PATH
set PATH $HOME/bin $PATH

# fd works better than find, less likely to get stuck in deep directories
set FZF_ALT_C_COMMAND "fd --type directory --hidden --follow"
set FZF_CTRL_T_COMMAND "fd --hidden --follow"

# Bash binding for editing current buffer in VS Code
# Ideally this would use the builtin edit_command_buffer but it
# chokes on arguments to `code`
bind \cx\ce edit_command_buffer_in_vs_code

# OS-specific stuff
switch (uname)
    case Linux
    #     echo Hi Tux! This is config.fish speaking
       set VISUAL /usr/bin/vim
       set DOTNET_ROOT $HOME/dotnet
       set PATH $HOME/dotnet $PATH
    case Darwin
#     echo Hi macOS! This is config.fish speaking
        set PATH $HOME/.jenv/bin $PATH
        status --is-interactive; and source (jenv init -|psub)
        # Make VS Code the default editor
        # set -Ux VISUAL code --wait --new-window
end
test -e {$HOME}/.iterm2_shell_integration.fish ; and source {$HOME}/.iterm2_shell_integration.fish

alias py3="python3"