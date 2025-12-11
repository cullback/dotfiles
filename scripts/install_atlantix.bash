#!/usr/bin/env bash
set -euxo pipefail

# NixOS Installation Script for atlantix (Hetzner Cloud with disko + facter)
# curl https://raw.githubusercontent.com/cullback/dotfiles/refs/heads/main/scripts/install_atlantix.bash | bash

echo "=== NixOS Installation Script for atlantix (EFI/disko/facter) ==="
echo ""

git clone https://github.com/cullback/dotfiles.git
cd dotfiles

echo "=== Generating hardware report with nixos-facter ==="
nix run github:nix-community/nixos-facter > hosts/atlantix/facter.json

echo "=== Running disko to partition and format disk ==="
nix run github:nix-community/disko -- --mode disko hosts/atlantix/disko.nix

echo "=== Installing NixOS ==="
nixos-install --flake ./hosts#atlantix --root /mnt

echo ""
echo "=== Installation complete ==="
echo "You can now reboot into your new NixOS system."
echo "After reboot, run: tailscale up --ssh"
