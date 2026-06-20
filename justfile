# Display available recipes
default:
    just --list --unsorted

alias fmt := format

nix-rebuild:
    sudo nixos-rebuild switch --flake ./hosts#$(hostname)

sync-dotfiles:
    bash scripts/install.bash

# apply a colorscheme across helix/ghostty/zellij/gitui (e.g. `just theme base16-gruvbox-material-dark-medium`)
theme name:
    tinty apply {{ name }}

# list your curated schemes (the cycle ring in tinty/config.toml)
themes:
    yq -p toml -oy '.rings[] | select(.name == "default") | .schemes[]' tinty/config.toml

# list every available scheme
themes-all:
    tinty list

# interactive scheme picker (all schemes)
theme-pick:
    tinty gallery

# advance to the next scheme in the cycle ring (live)
theme-cycle:
    tinty cycle

# auto-cycle the ring every N seconds, live (ctrl-c to stop)
theme-loop seconds="8":
    #!/usr/bin/env fish
    while true
        tinty cycle
        sleep {{ seconds }}
    end

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
