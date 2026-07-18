#!/usr/bin/env bash

# Symlinks the config files to their correct locations and names.
# Works on both NixOS/Linux and macOS, and is idempotent.

set -euo pipefail

dotfiles="$(git rev-parse --show-toplevel)"

# Links shared across every host, as "<repo-relative src>" "<HOME-relative dest>" pairs.
links=(
    "fish/config.fish" ".config/fish/config.fish"
    "fish/catppuccin-frappe.theme" ".config/fish/themes/catppuccin-frappe.theme"
    "git/config.toml" ".config/git/config"
    "git/ignore" ".config/git/ignore"
    "git/pre-commit.fish" ".config/git/hooks/pre-commit"
    "git/post-checkout.fish" ".config/git/hooks/post-checkout"
    "zellij/config.kdl" ".config/zellij/config.kdl"
    "agents/CLAUDE.md" ".claude/CLAUDE.md"
    "agents/claude.json" ".claude/settings.json"
    "helix/config.toml" ".config/helix/config.toml"
    "helix/languages.toml" ".config/helix/languages.toml"
    "dprint/dprint.json" ".config/dprint/dprint.json"
    "harper-ls/dictionary.txt" ".config/harper-ls/dictionary.txt"
    "starship/starship.toml" ".config/starship.toml"
    "yazi/theme.toml" ".config/yazi/theme.toml"
    "visidata/config.py" ".config/visidata/config.py"
    "gitui/theme.ron" ".config/gitui/theme.ron"
    "ghostty/config" ".config/ghostty/config"
    "voxtype/config.toml" ".config/voxtype/config.toml"
    "voxtype/voxtype.service" ".config/systemd/user/voxtype.service"
    "beets/config.yaml" ".config/beets/config.yaml"
    "scripts/pdf2md.py" ".local/bin/pdf2md"
    "scripts/yt_archive.fish" ".local/bin/yt-archive"
    "scripts/single_file.fish" ".local/bin/single-file-archive"
)

# macOS-only links (karabiner is mac-only; alacritty lives here too).
if [ "$(uname)" = "Darwin" ]; then
    links+=(
        "karabiner/bold_layout.json" ".config/karabiner/assets/complex_modifications/bold_layout.json"
        "karabiner/capslock.json" ".config/karabiner/assets/complex_modifications/capslock.json"
        "alacritty/alacritty.toml" ".config/alacritty/alacritty.toml"
        "alacritty/catppuccin-frappe.toml" ".config/alacritty/catppuccin-frappe.toml"
    )
fi

i=0
while [ "$i" -lt "${#links[@]}" ]; do
    src="$dotfiles/${links[$i]}"
    dest="$HOME/${links[$((i + 1))]}"
    i=$((i + 2))
    if [ ! -e "$src" ]; then
        echo "Skipping missing source $src"
        continue
    fi
    mkdir -p "$(dirname "$dest")"
    echo "Symlinking $src -> $dest"
    ln -sf "$src" "$dest"
done
