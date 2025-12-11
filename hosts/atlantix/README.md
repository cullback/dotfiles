# Atlantix

VPS running various services. Hosted on Hetzner Cloud with BIOS boot.

## Modern NixOS Stack

This host uses:

- **disko** for declarative disk partitioning
- **nixos-facter** for automatic hardware detection
- **GRUB** with BIOS/MBR boot

## Installation

Run the automated installation script:

```bash
curl https://raw.githubusercontent.com/cullback/dotfiles/refs/heads/main/scripts/install_atlantix.bash | bash
```

This will:

1. Generate hardware report with nixos-facter
2. Partition disk with disko
3. Install NixOS with the atlantix configuration

## Manual Hardware Report Generation

If you need to regenerate the hardware report after hardware changes:

```bash
nix run github:nix-community/nixos-facter > hosts/atlantix/facter.json
git add hosts/atlantix/facter.json
git commit -m "Update hardware report"
```

## Updating

```bash
cd ~/dotfiles/hosts
git pull
sudo nixos-rebuild switch --flake .#atlantix

# regenerate
sudo nix run --option experimental-features "nix-command flakes" nixpkgs#nixos-facter -- -o ./hosts/atlantix/facter.json
```

## Set up SSH keys

```shell
# Create directory
ssh cullback@<ip_address> "mkdir -p ~/.ssh && chmod 700 ~/.ssh"
scp ~/.ssh/id_ed25519 cullback@<ip_address>:/home/cullback/.ssh/
scp ~/.ssh/id_ed25519.pub cullback@<ip_address>:/home/cullback/.ssh/

# Then SSH in and fix permissions
ssh cullback@<ip_address>
chmod 700 ~/.ssh
chmod 600 ~/.ssh/id_ed25519
chmod 644 ~/.ssh/id_ed25519.pub
```
