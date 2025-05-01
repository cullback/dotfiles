#!/usr/bin/env fish

# function get_secret -a key
#     keepassxc-cli show -a password "$HOME/secrets.kdbx" \
#         --key-file "$HOME/keepass.keyx" \
#         --no-password "$key"
#     # keychain way
#     # security find-generic-password -a "$USER" -s "$key" -w
# end

# set -gx OPENROUTER_API_KEY (get_secret "OPENROUTER_API_KEY")

fish_add_path --move /opt/homebrew/bin
fish_add_path --move /opt/homebrew/opt/rustup/bin/
fish_add_path --move $HOME/.local/bin/

set -gx SHELL (which fish)
set -gx EDITOR hx

if status is-interactive
    set fish_greeting # Suppress fish welcome message

    fish_config theme choose catppuccin-frappe
    fish_config prompt choose Arrow

    # fzf
    fzf --fish | source
    set -gx FZF_DEFAULT_COMMAND "fd --type f"
    set -gx FZF_CTRL_T_COMMAND $FZF_DEFAULT_COMMAND
    set -gx FZF_CTRL_T_OPTS "--preview 'bat -n --color=always {}'"
    set -gx FZF_ALT_C_COMMAND "fd --type d"
    set -gx FZF_ALT_C_OPTS "--preview 'tree -C {}'"
end
