function fish_right_prompt
    if test -n "$CMD_DURATION"; and test $CMD_DURATION -gt 3000
        set_color 9a9996
        printf '%.1fs' (math $CMD_DURATION / 1000)
        set_color normal
    end
end
