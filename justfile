install:
    ./scripts/install.fish

update-packages:
    brew bundle install --file homebrew/Brewfile

clean-packages:
    brew bundle cleanup --file homebrew/Brewfile --force

nix-rebuild:
    sudo nixos-rebuild switch -I nixos-config=hosts/$(hostname)/configuration.nix
