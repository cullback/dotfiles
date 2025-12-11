# Set up

## Set up partitions

```shell
curl https://raw.githubusercontent.com/cullback/dotfiles/refs/heads/main/scripts/install_nixos.bash | bash
```

## Set up SSH keys

```shell
# Create directory
ssh cullback@155.138.148.34 "mkdir -p ~/.ssh && chmod 700 ~/.ssh"
scp ~/.ssh/id_ed25519 cullback@155.138.148.34:/home/cullback/.ssh/
scp ~/.ssh/id_ed25519.pub cullback@155.138.148.34:/home/cullback/.ssh/

# Then SSH in and fix permissions
ssh cullback@155.138.148.34
chmod 700 ~/.ssh
chmod 600 ~/.ssh/id_ed25519
chmod 644 ~/.ssh/id_ed25519.pub
```

## Clone dotfiles

```shell
mkdir /home/cullback/repos
git clone git@github.com:cullback/dotfiles.git
```
