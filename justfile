nix-rebuild:
    sudo nixos-rebuild switch --flake ./hosts#$(hostname)

sync-dotfiles:
    fish hosts/$(hostname)/install.fish

check:
    #!/usr/bin/env fish
    set status_flag 0
    dprint check --config dprint/dprint.json; or set status_flag 1
    # fd -e nix | xargs -r nixfmt --check; or set status_flag 1
    fd -e fish | xargs -r fish_indent --check; or set status_flag 1
    exit $status_flag

format:
    dprint fmt --config dprint/dprint.json
    fd -e nix | xargs -r nixfmt
    fd -e fish | xargs -r fish_indent -w
    just --unstable --fmt
