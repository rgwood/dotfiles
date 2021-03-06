function fish_prompt --description 'Write out the prompt'
	
    set -l last_status $status

    if test $last_status -ne 0
        printf "%s(%d)%s " (set_color red --bold) $last_status (set_color normal)
    end

    set -l color_cwd
    set -l suffix
    switch "$USER"
        case root toor
            if set -q fish_color_cwd_root
                set color_cwd $fish_color_cwd_root
            else
                set color_cwd $fish_color_cwd
            end
            set suffix '#'
        case '*'
            set color_cwd $fish_color_cwd
            set suffix '❯'
    end

    if not set -q ANONYMOUS_PROMPT
        echo -s (set_color $fish_color_comment) "$USER" @ (prompt_hostname) ' ' (set_color $color_cwd) (prompt_pwd)
    end
    echo -n -s (set_color --bold cyan) "$suffix "
end
