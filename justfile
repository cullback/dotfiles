nix-rebuild:
    sudo nixos-rebuild switch -I nixos-config=hosts/$(hostname)/configuration.nix

check:
    dprint check --config dprint/dprint.json
    fd -e nix | xargs nixfmt --check

format:
    dprint fmt --config dprint/dprint.json
    fd -e nix | xargs nixfmt
