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
    "agents/AGENTS3.md" ".claude/CLAUDE.md"
    "agents/claude.json" ".claude/settings.json"
    "helix/config.toml" ".config/helix/config.toml"
    "helix/languages.toml" ".config/helix/languages.toml"
    "dprint/dprint.json" ".config/dprint/dprint.json"
    "harper-ls/dictionary.txt" ".config/harper-ls/dictionary.txt"
    "starship/starship.toml" ".config/starship.toml"
    "yazi/theme.toml" ".config/yazi/theme.toml"
    "visidata/config.py" ".config/visidata/config.py"
    "gitui/theme.ron" ".config/gitui/theme.ron"
)

# macOS-only links (karabiner is mac-only; alacritty lives here too).
if [ "$(uname)" = "Darwin" ]; then
    links+=(
        "karabiner/bold_layout.json" ".config/karabiner/assets/complex_modifications/bold_layout.json"
        "karabiner/capslock.json" ".config/karabiner/assets/complex_modifications/capslock.json"
        "alacritty/alacritty.toml" ".config/alacritty/alacritty.toml"
        "alacritty/catppuccin-frappe.toml" ".config/alacritty/catppuccin-frappe.toml"
        "ghostty/config" ".config/ghostty/config"
        "tinty/config.toml" ".config/tinted-theming/tinty/config.toml"
        "tinty/apply.fish" ".config/tinty/apply.fish"
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

# Bootstrap the colorscheme on macOS (where the tinty configs above are linked):
# clone the tinted-helix template, build its base24 themes, and generate the
# Helix/Ghostty/Zellij/gitui theme files so the configs resolve on a fresh box.
if [ "$(uname)" = "Darwin" ]; then
    if command -v tinty >/dev/null 2>&1; then
        tinty install || true
        # tinted-helix ships only base16 renders; build the clone to add base24.
        helix_repo="$(tinty config --data-dir-path 2>/dev/null)/repos/helix"
        [ -d "$helix_repo" ] && tinty build "$helix_repo" || true
        tinty apply base16-catppuccin-frappe || true
    else
        echo "tinty not found on PATH; run 'brew install tinty' then 'tinty install'"
    fi
fi
