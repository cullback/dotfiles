#!/usr/bin/env fish

set -gx EDITOR hx
set -gx COLORTERM truecolor
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

    # Launch Yazi and change this shell to Yazi's directory when it exits.
    function yazi --description 'Yazi file manager (cd on exit)'
        set -l tmp (mktemp -t "yazi-cwd.XXXXXX")
        set -l restart (mktemp -t "yazi-restart.XXXXXX")
        set -lx YAZI_RESTART_FILE $restart
        set -l yazi_status 0

        while true
            rm -f -- $tmp $restart
            command yazi $argv --cwd-file=$tmp
            set yazi_status $status

            if test -s $tmp
                set -l cwd (command cat -- $tmp)
                if test -n "$cwd" -a "$cwd" != "$PWD"
                    cd -- $cwd
                    commandline -f repaint
                end
            end

            test -e $restart; or break
            set argv
        end

        rm -f -- $tmp $restart
        return $yazi_status
    end

    function yy --wraps yazi --description 'Alias for the Yazi shell wrapper'
        yazi $argv
    end

    # wt: create/manage git worktrees, and cd into freshly created ones.
    # The underlying script prints the new worktree path on stdout; a
    # subprocess can't cd the parent shell, so wrap it here.
    function wt --description 'git worktree helper (cds into new worktrees)'
        set -l out (/vault/repos/dotfiles/scripts/wt.fish $argv)
        or return $status
        if set -q out[-1]; and test -d "$out[-1]"
            cd $out[-1]
        else
            printf '%s\n' $out
        end
    end
end
