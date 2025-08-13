symlink-configs:
    ./scripts/install.fish

update-packages:
    brew bundle install --file homebrew/Brewfile

clean-packages:
    brew bundle cleanup --file homebrew/Brewfile --force
