function fish_prompt
    set -l last_status $status

    set_color 99c1f1
    printf '%s' (prompt_pwd)
    set_color normal

    set -l branch (command git symbolic-ref --short HEAD 2>/dev/null)
    if test -n "$branch"
        set_color 9a9996
        printf '  '
        set_color dc8add
        printf ' %s' $branch
        if not command git diff --quiet --ignore-submodules HEAD 2>/dev/null
            set_color f66151
            printf ' ●'
        end
        set_color normal
    end

    printf '\n'
    if test $last_status -ne 0
        set_color f66151
        printf '✗ '
    else
        set_color 8ff0a4
        printf '❯ '
    end
    set_color normal
end
