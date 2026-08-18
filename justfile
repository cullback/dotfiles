# Display available recipes
default:
    just --list --unsorted

alias fmt := format

nix-rebuild:
    sudo nixos-rebuild switch --flake ./hosts#$(hostname)

# Bump flake inputs (all, or named ones e.g. `just update nixpkgs-unstable`) and rebuild
update *inputs:
    nix flake update {{ inputs }} --flake ./hosts
    just nix-rebuild

sync-dotfiles:
    bash scripts/install.bash

check:
    #!/usr/bin/env fish
    set status_flag 0
    dprint check --config dprint/dprint.json; or set status_flag 1
    if command -q nixfmt
        fd -e nix | xargs -r nixfmt --check; or set status_flag 1
    else
        echo "⚠️  nixfmt not found, skipping nix format check"
    end
    fd -e fish | xargs -r fish_indent --check; or set status_flag 1
    exit $status_flag

format:
    dprint fmt --config dprint/dprint.json
    command -v nixfmt >/dev/null && fd -e nix | xargs -r nixfmt || echo "⚠️  nixfmt not found, skipping nix format"
    fd -e fish | xargs -r fish_indent -w
    just --unstable --fmt
