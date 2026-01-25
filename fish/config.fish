#!/usr/bin/env fish

set -gx EDITOR hx
set -gx COLORTERM truecolor
# set -gx OPENROUTER_API_KEY (security find-generic-password -a "$USER" -s "openrouter-api-key" -w)

if status is-interactive
    set fish_greeting # Suppress fish welcome message
    fish_config theme choose catppuccin-frappe

    alias ls='eza'
    alias ll='eza -l --git'
    alias la='eza -la --git'
    alias lt='eza --tree'
    alias tree='eza --tree'
    alias cat='bat'
    # alias less='bat'

    # fzf
    fzf --fish | source
    set -gx FZF_DEFAULT_COMMAND "fd --type f"
    set -gx FZF_CTRL_T_COMMAND $FZF_DEFAULT_COMMAND
    set -gx FZF_CTRL_T_OPTS "--preview 'bat -n --color=always {}'"
    set -gx FZF_ALT_C_COMMAND "fd --type d"
    set -gx FZF_ALT_C_OPTS "--preview 'tree -C {}'"

    starship init fish | source
end
