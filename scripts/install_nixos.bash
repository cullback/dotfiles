#!/usr/bin/env bash
set -euxo pipefail

# NixOS Installation Script for Hetzner Cloud (BIOS/GPT)
# curl https://raw.githubusercontent.com/cullback/dotfiles/refs/heads/main/scripts/install_nixos.bash | bash

echo "=== NixOS Installation Script (BIOS/GPT) ==="
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

echo "=== Detected disk: $DISK ==="

# Determine partition naming
if [[ "$DISK" == *"nvme"* ]]; then
    BIOS_PART="${DISK}p1"
    ROOT_PART="${DISK}p2"
else
    BIOS_PART="${DISK}1"
    ROOT_PART="${DISK}2"
fi

echo "=== Unmounting any existing partitions ==="
# Unmount recursively in case /mnt/boot is mounted
umount -R /mnt 2>/dev/null || true
# Unmount individual partitions if they're mounted elsewhere
umount "${DISK}"* 2>/dev/null || true

# Give the system a moment to release the partitions
sleep 1

echo "=== Partitioning $DISK (GPT/BIOS) ==="
echo "Creating GPT partition table with BIOS boot partition..."
parted --script "$DISK" -- mklabel gpt
parted --script "$DISK" -- mkpart primary 1MB 2MB
parted --script "$DISK" -- set 1 bios_grub on
parted --script "$DISK" -- mkpart primary ext4 2MB 100%

# Wait for kernel to recognize new partitions
sleep 2
partprobe "$DISK" || true

echo "=== Formatting partitions ==="
# No formatting needed for BIOS boot partition
mkfs.ext4 -F -L nixos "$ROOT_PART"

echo "=== Mounting filesystems ==="
mount "$ROOT_PART" /mnt

echo "=== Generating configuration ==="
nixos-generate-config --root /mnt

echo ""
echo "=== Installation ready ==="
echo "Disk: $DISK"
echo "BIOS boot partition: $BIOS_PART (1MB, unformatted)"
echo "Root partition: $ROOT_PART"

git clone https://github.com/cullback/dotfiles.git

# nixos-install --flake ./hosts#shodan --root /mnt
