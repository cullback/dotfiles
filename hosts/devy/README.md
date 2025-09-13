# Nix dev

## Set up partitions

```shell
# nix os install
parted /dev/sda -- mklabel gpt
parted /dev/sda -- mkpart ESP fat32 1MB 512MB    # boot partition (partition 1)
parted /dev/sda -- mkpart root ext4 512MB 100%   # root partition (partition 2)
parted /dev/sda -- set 1 esp on                  # set ESP flag on partition 1
mkfs.fat -F 32 -n boot /dev/sda1                 # format boot partition
mkfs.ext4 -L nixos /dev/sda2                     # format root partition

mount /dev/sda2 /mnt         # mount root
mkdir -p /mnt/boot
mount /dev/sda1 /mnt/boot    # mount boot

nixos-generate-config --root /mnt
nixos-install
```

1. set up ssh keys

```
sudo nixos-rebuild switch -I nixos-config=hosts/dev/configuration.nix
```
