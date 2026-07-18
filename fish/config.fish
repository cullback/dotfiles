#!/usr/bin/env fish

set -gx EDITOR hx
set -gx COLORTERM truecolor
set -gx PLAYBOOK /vault/repos/playbook
fish_add_path --global ~/.local/bin

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
    command -q direnv; and direnv hook fish | source

    # wt: create/manage git worktrees, and cd into freshly created ones.
    # The underlying script prints the new worktree path on stdout; a
    # subprocess can't cd the parent shell, so wrap it here.
    function wt --description 'git worktree helper (cds into new worktrees)'
        set -l out ($PLAYBOOK/bin/wt.fish $argv)
        or return $status
        if set -q out[-1]; and test -d "$out[-1]"
            cd $out[-1]
        else
            printf '%s\n' $out
        end
    end
end
