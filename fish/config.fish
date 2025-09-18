#!/usr/bin/env fish

set -gx EDITOR hx

if status is-interactive
    set fish_greeting # Suppress fish welcome message
    fish_config theme choose catppuccin-frappe

    alias ls='eza'
    alias ll='eza -l --git'
    alias la='eza -la --git'
    alias lt='eza --tree'
    alias tree='eza --tree'
    alias cat='bat'
    alias less='bat'

    # fzf
    fzf --fish | source
    set -gx FZF_DEFAULT_COMMAND "fd --type f"
    set -gx FZF_CTRL_T_COMMAND $FZF_DEFAULT_COMMAND
    set -gx FZF_CTRL_T_OPTS "--preview 'bat -n --color=always {}'"
    set -gx FZF_ALT_C_COMMAND "fd --type d"
    set -gx FZF_ALT_C_OPTS "--preview 'tree -C {}'"
end

function nix-shell
    command nix-shell $argv --run fish
end

function nix
    command nix $argv --command fish
end
