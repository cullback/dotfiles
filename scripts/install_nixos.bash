#!/usr/bin/env bash
set -euxo pipefail

# NixOS Installation Script with MBR/GPT support
# Usage: 
#   bash install.sh mbr   # For x86 Hetzner instances
#   bash install.sh gpt   # For arm64 instances or EFI systems

echo "=== NixOS Installation Script ==="
echo ""

# Check argument
BOOT_MODE="${1:-}"
if [[ "$BOOT_MODE" != "mbr" && "$BOOT_MODE" != "gpt" ]]; then
    echo "Usage: $0 [mbr|gpt]"
    echo ""
    echo "  mbr - BIOS/MBR boot (use for x86 Hetzner instances)"
    echo "  gpt - UEFI/GPT boot (use for arm64 instances)"
    exit 1
fi

echo "Boot mode: $BOOT_MODE"
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
echo "=== Partitioning $DISK with $BOOT_MODE ==="

# Determine partition naming
if [[ "$DISK" == *"nvme"* ]]; then
    PART1="${DISK}p1"
    PART2="${DISK}p2"
else
    PART1="${DISK}1"
    PART2="${DISK}2"
fi

if [ "$BOOT_MODE" = "gpt" ]; then
    # GPT/UEFI partitioning
    echo "Creating GPT partition table with ESP boot partition..."
    parted "$DISK" -- mklabel gpt
    parted "$DISK" -- mkpart ESP fat32 1MB 512MB
    parted "$DISK" -- mkpart root ext4 512MB 100%
    parted "$DISK" -- set 1 esp on
    
    echo "=== Formatting partitions ==="
    mkfs.fat -F 32 -n boot "$PART1"
    mkfs.ext4 -L nixos "$PART2"
    
    echo "=== Mounting filesystems ==="
    mount "$PART2" /mnt
    mkdir -p /mnt/boot
    mount "$PART1" /mnt/boot
    
    BOOT_PARTITION="$PART1"
    ROOT_PARTITION="$PART2"
else
    # MBR/BIOS partitioning
    echo "Creating MBR partition table with single partition..."
    parted "$DISK" -- mklabel msdos
    parted "$DISK" -- mkpart primary ext4 1MB 100%
    parted "$DISK" -- set 1 boot on
    
    echo "=== Formatting partition ==="
    mkfs.ext4 -L nixos "$PART1"
    
    echo "=== Mounting filesystem ==="
    mount "$PART1" /mnt
    
    ROOT_PARTITION="$PART1"
fi

echo "=== Generating configuration ==="
nixos-generate-config --root /mnt

echo ""
echo "=== Installation ready ==="
echo "Disk: $DISK"
echo "Boot mode: $BOOT_MODE"
if [ "$BOOT_MODE" = "gpt" ]; then
    echo "Boot partition: $BOOT_PARTITION"
fi
echo "Root partition: $ROOT_PARTITION"
echo ""
echo "Next steps:"
echo "1. Edit /mnt/etc/nixos/configuration.nix"
if [ "$BOOT_MODE" = "gpt" ]; then
    echo "   - Ensure boot.loader.systemd-boot.enable = true;"
    echo "   - Ensure boot.loader.efi.canTouchEfiVariables = true;"
else
    echo "   - Change to: boot.loader.grub.enable = true;"
    echo "   - Set: boot.loader.grub.device = \"$DISK\";"
    echo "   - Remove any systemd-boot or EFI settings"
fi
echo "2. Run: nixos-install"
echo "3. Run: reboot"

# Uncomment to auto-download your config:
# curl -L https://raw.githubusercontent.com/cullback/dotfiles/refs/heads/main/hosts/vultr/configuration.nix -o /mnt/etc/nixos/configuration.nix
# nixos-install
# reboot
