# Display available recipes
default:
    just --list --unsorted

# Rebuild this host and switch to the new generation
nix-rebuild:
    sudo nixos-rebuild switch --flake ./hosts#$(hostname)

# Stage the result for reboot: a live switch may stop an active desktop session
# when an update changes GNOME's user units.
[doc('Bump flake inputs (all, or named ones e.g. `just update nixpkgs-unstable`)')]
update *inputs:
    nix flake update {{ inputs }} --flake ./hosts
    sudo nixos-rebuild boot --flake ./hosts#$(hostname)
    @echo "Update staged; reboot to activate it."

# Symlink this repo's config files into place under $HOME
sync-dotfiles:
    bash scripts/install.bash

alias fmt := format

# Format every configured file type
format:
    just --fmt
    dprint fmt --config dprint/dprint.json
    fd -e nix -X nixfmt
    fd -e fish -X fish_indent -w

# Run non-mutating formatter checks
check:
    just --fmt --check
    dprint check --config dprint/dprint.json
    fd -e nix -X nixfmt --check
    fd -e fish -X fish_indent --check
