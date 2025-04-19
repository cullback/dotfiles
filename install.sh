#!/usr/bin/env bash

# This script symlinks the config files to their correct locations and names.
# It is idempotent

# set dotfiles (realpath (status dirname))
dotfiles=$(realpath "$(dirname "$0")")
echo "$dotfiles"


# karabiner elements
mkdir -p "$HOME/.config/karabiner/assets/complex_modifications/"
ln -sf "$dotfiles/karabiner/bold_layout.json" "$HOME/.config/karabiner/assets/complex_modifications/"
ln -sf "$dotfiles/karabiner/capslock.json" "$HOME/.config/karabiner/assets/complex_modifications/"

# git
ln -sf "$dotfiles/git/config.toml" "$HOME/.gitconfig"
ln -sf "$dotfiles/git/.gitignore_global" "$HOME/.gitignore_global"
ln -sf "$dotfiles/git/.ignore" "$HOME/.ignore"
