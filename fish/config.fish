#!/usr/bin/env fish

set -gx EDITOR hx

if status is-interactive
    set fish_greeting # Suppress fish welcome message
    fish_config theme choose catppuccin-frappe

    # fzf
    fzf --fish | source
    set -gx FZF_DEFAULT_COMMAND "fd --type f"
    set -gx FZF_CTRL_T_COMMAND $FZF_DEFAULT_COMMAND
    set -gx FZF_CTRL_T_OPTS "--preview 'bat -n --color=always {}'"
    set -gx FZF_ALT_C_COMMAND "fd --type d"
    set -gx FZF_ALT_C_OPTS "--preview 'tree -C {}'"
end
