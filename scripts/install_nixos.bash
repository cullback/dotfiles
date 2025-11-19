#!/usr/bin/env bash
set -euxo pipefail

# NixOS Installation Script for Hetzner Cloud
# curl https://raw.githubusercontent.com/cullback/dotfiles/main/scripts/install_nixos.bash | bash
# Usage: bash install_nixos.bash

echo "=== NixOS Installation Script (UEFI/GPT) ==="
echo ""

# Detect disk (try common names)
DISK=""
for d in /dev/sda /dev/vda /dev/nvme0n1; do
    if [ -b "$d" ]; then
        DISK="$d"
        break
    fi
done

if [ -z "$DISK" ]; then
    echo "Error: Could not detect disk. Please run 'lsblk' and edit the script."
    exit 1
fi

echo "=== Partitioning $DISK (GPT/UEFI) ==="

# Determine partition naming
if [[ "$DISK" == *"nvme"* ]]; then
    BOOT_PART="${DISK}p1"
    ROOT_PART="${DISK}p2"
else
    BOOT_PART="${DISK}1"
    ROOT_PART="${DISK}2"
fi

# GPT/UEFI partitioning
echo "Creating GPT partition table with ESP boot partition..."
parted "$DISK" -- mklabel gpt
parted "$DISK" -- mkpart ESP fat32 1MB 512MB
parted "$DISK" -- mkpart root ext4 512MB 100%
parted "$DISK" -- set 1 esp on

echo "=== Formatting partitions ==="
mkfs.fat -F 32 -n boot "$BOOT_PART"
mkfs.ext4 -L nixos "$ROOT_PART"

echo "=== Mounting filesystems ==="
mount "$ROOT_PART" /mnt
mkdir -p /mnt/boot
mount "$BOOT_PART" /mnt/boot

echo "=== Generating configuration ==="
nixos-generate-config --root /mnt

echo ""
echo "=== Installation ready ==="
echo "Disk: $DISK"
echo "Boot partition: $BOOT_PART (ESP)"
echo "Root partition: $ROOT_PART"
echo ""
echo "Next steps:"
echo "1. Edit /mnt/etc/nixos/configuration.nix"
echo "   - Ensure boot.loader.systemd-boot.enable = true;"
echo "   - Ensure boot.loader.efi.canTouchEfiVariables = true;"
echo "2. Run: nixos-install"
echo "3. Run: reboot"

# Uncomment to auto-download your config:
# curl -L https://raw.githubusercontent.com/cullback/dotfiles/refs/heads/main/hosts/hetzner/configuration.nix -o /mnt/etc/nixos/configuration.nix
# nixos-install
# reboot
