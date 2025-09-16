#!/usr/bin/env fish

# This script symlinks the config files to their correct locations and names.
# It is idempotent

# get the dotfiles script path
set -l dotfiles (git rev-parse --show-toplevel)

set -l links \
    "karabiner/bold_layout.json" ".config/karabiner/assets/complex_modifications/bold_layout.json" \
    "karabiner/capslock.json" ".config/karabiner/assets/complex_modifications/capslock.json" \
    "alacritty/alacritty.toml" ".config/alacritty/alacritty.toml" \
    "alacritty/catppuccin-frappe.toml" ".config/alacritty/catppuccin-frappe.toml"

for i in (seq 1 2 (count $links))
    set -l src $dotfiles/$links[$i]
    set -l dest $HOME/$links[(math $i + 1)]
    mkdir -p (dirname $dest)
    echo "Symlinking $src -> $dest"
    ln -sf $src $dest
end
