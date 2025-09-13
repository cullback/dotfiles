# macOS

```bash
# install command line tools
xcode-select --install

# install homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# install dotfiles and symlink configs
git clone dotfiles
bash install.sh

brew bundle install

# change shell to fish
which fish | sudo tee -a /etc/shells
chsh -s $(which fish)

# ssh key
ssh-keygen -t ed25519 -C "cullback@fastmail.com"
```


