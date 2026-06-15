#!/usr/bin/env fish

# Symlinks the config files to their correct locations and names.
# Works on both NixOS/Linux and macOS, and is idempotent.

set -l dotfiles (git rev-parse --show-toplevel)

# Links shared across every host: "<repo-relative src>" "<HOME-relative dest>"
set -l links \
    "fish/config.fish" ".config/fish/config.fish" \
    "fish/catppuccin-frappe.theme" ".config/fish/themes/catppuccin-frappe.theme" \
    "git/config.toml" ".config/git/config" \
    git/ignore ".config/git/ignore" \
    "git/pre-commit.fish" ".config/git/hooks/pre-commit" \
    "git/post-checkout.fish" ".config/git/hooks/post-checkout" \
    "zellij/config.kdl" ".config/zellij/config.kdl" \
    "agents/AGENTS3.md" ".claude/CLAUDE.md" \
    "agents/claude.json" ".claude/settings.json" \
    "helix/config.toml" ".config/helix/config.toml" \
    "helix/languages.toml" ".config/helix/languages.toml" \
    "dprint/dprint.json" ".config/dprint/dprint.json" \
    "harper-ls/dictionary.txt" ".config/harper-ls/dictionary.txt" \
    "starship/starship.toml" ".config/starship.toml" \
    "yazi/theme.toml" ".config/yazi/theme.toml" \
    "visidata/config.py" ".config/visidata/config.py" \
    "gitui/theme.ron" ".config/gitui/theme.ron"

# macOS-only links (karabiner is mac-only; alacritty lives here too).
if test (uname) = Darwin
    set -a links \
        "karabiner/bold_layout.json" ".config/karabiner/assets/complex_modifications/bold_layout.json" \
        "karabiner/capslock.json" ".config/karabiner/assets/complex_modifications/capslock.json" \
        "alacritty/alacritty.toml" ".config/alacritty/alacritty.toml" \
        "alacritty/catppuccin-frappe.toml" ".config/alacritty/catppuccin-frappe.toml"
end

for i in (seq 1 2 (count $links))
    set -l src $dotfiles/$links[$i]
    set -l dest $HOME/$links[(math $i + 1)]
    if not test -e $src
        echo "Skipping missing source $src"
        continue
    end
    mkdir -p (dirname $dest)
    echo "Symlinking $src -> $dest"
    ln -sf $src $dest
end
