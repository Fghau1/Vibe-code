if status is-interactive
    set -g fish_greeting

    set -gx EDITOR nvim

    if command -v eza >/dev/null
        alias ls 'eza --icons --group-directories-first'
        alias ll 'eza -la --icons --group-directories-first'
        alias lt 'eza --tree --icons --level=2'
    end
    if command -v bat >/dev/null
        alias cat 'bat --theme=ansi --paging=never'
    end
    alias g git

    if command -v fzf >/dev/null
        fzf --fish | source
    end

    if command -v fastfetch >/dev/null; and not set -q FASTFETCH_SHOWN
        set -gx FASTFETCH_SHOWN 1
    end
end

# ── Adwaita Darker (matches kitty/current-theme.conf) ──
set -g fish_color_normal deddda
set -g fish_color_command 99c1f1
set -g fish_color_keyword dc8add
set -g fish_color_quote 8ff0a4
set -g fish_color_redirection ffa348
set -g fish_color_end 93ddc2
set -g fish_color_error f66151
set -g fish_color_param deddda
set -g fish_color_comment 9a9996
set -g fish_color_selection --background=303030
set -g fish_color_search_match ffa348 --background=262626
set -g fish_color_operator dc8add
set -g fish_color_escape 93ddc2
set -g fish_color_autosuggestion 5a5a5a
set -g fish_color_cwd 99c1f1
set -g fish_color_cancel f66151
set -g fish_pager_color_prefix dc8add --bold
set -g fish_pager_color_completion deddda
set -g fish_pager_color_description 9a9996
set -g fish_pager_color_progress 99c1f1 --background=262626
set -g fish_pager_color_selected_background --background=262626
set -gx PATH $HOME/.local/bin $PATH
