#!/usr/bin/env fish

# This script symlinks the config files to their correct locations and names.
# It is idempotent

# get the dotfiles script path
set -l dotfiles (git rev-parse --show-toplevel)

set -l links \
    "fish/config.fish" ".config/fish/config.fish" \
    "fish/catppuccin-frappe.theme" ".config/fish/themes/catppuccin-frappe.theme" \
    "git/config.toml" ".config/git/config" \
    git/ignore ".config/git/ignore" \
    "git/pre-commit.fish" ".config/git/hooks/pre-commit" \
    "zellij/config.kdl" ".config/zellij/config.kdl" \
    "agents/AGENTS.md" ".claude/CLAUDE.md" \
    "agents/claude.json" ".claude/settings.json" \
    "helix/config.toml" ".config/helix/config.toml" \
    "dprint/dprint.json" ".config/dprint/dprint.json" \
    "helix/languages.toml" ".config/helix/languages.toml" \
    "marksman/config.toml" ".config/marksman/config.toml" \
    "starship/starship.toml" ".config/starship.toml" \
    "yazi/theme.toml" ".config/yazi/theme.toml" \
    "gitui/theme.ron" ".config/gitui/theme.ron"

for i in (seq 1 2 (count $links))
    set -l src $dotfiles/$links[$i]
    set -l dest $HOME/$links[(math $i + 1)]
    mkdir -p (dirname $dest)
    echo "Symlinking $src -> $dest"
    ln -sf $src $dest
end
