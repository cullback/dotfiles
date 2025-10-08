#!/usr/bin/env bash
set -euxo pipefail

# Simple NixOS Installation Script
# Usage: curl -L <script-url> | bash
# Or: bash nixos-install.sh

echo "=== NixOS Installation Script ==="
echo ""

# Detect disk (try common names)
DISK=""
for d in /dev/vda /dev/sda /dev/nvme0n1; do
    if [ -b "$d" ]; then
        DISK="$d"
        break
    fi
done

if [ -z "$DISK" ]; then
    echo "Error: Could not detect disk. Please run 'lsblk' and edit the script."
    exit 1
fi

echo "Detected disk: $DISK"
echo ""
read -p "This will ERASE ALL DATA on $DISK. Continue? (yes/no): " confirm

if [ "$confirm" != "yes" ]; then
    echo "Aborted."
    exit 0
fi

echo ""
echo "=== Partitioning $DISK ==="

# Determine partition naming
if [[ "$DISK" == *"nvme"* ]]; then
    BOOT="${DISK}p1"
    ROOT="${DISK}p2"
else
    BOOT="${DISK}1"
    ROOT="${DISK}2"
fi

# Create partitions
parted "$DISK" -- mklabel gpt
parted "$DISK" -- mkpart ESP fat32 1MB 512MB
parted "$DISK" -- mkpart root ext4 512MB 100%
parted "$DISK" -- set 1 esp on

echo "=== Formatting partitions ==="
mkfs.fat -F 32 -n boot "$BOOT"
mkfs.ext4 -L nixos "$ROOT"

echo "=== Mounting filesystems ==="
mount "$ROOT" /mnt
mkdir -p /mnt/boot
mount "$BOOT" /mnt/boot
