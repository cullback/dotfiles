nix-rebuild:
    sudo nixos-rebuild switch --flake ./hosts#$(hostname)

sync-dotfiles:
    bash scripts/install.bash

# apply a colorscheme across helix/ghostty/zellij/gitui (e.g. `just theme base16-gruvbox-material-dark-medium`)
theme name:
    tinty apply {{ name }}

# list available schemes
themes:
    tinty list

# interactive scheme picker
theme-pick:
    tinty gallery

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
