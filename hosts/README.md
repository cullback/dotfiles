# Hosts

NixOS hosts

## Router

- todo...

## Dev

- virtual machine for development
- common developer tools
- main programming environemnt

## NAS

- runs a bunch of services

## Mac

- homebrew for casks
- keep it simple
- alacritty, karabiner-elements

## Hostnames

- Asterix and obelix characters?
- <https://namingschemes.com/Psychotic_Computers>

## Notes

for vultr hosts, use

```nix
boot.loader.grub = {
  enable = true;
  device = "/dev/vda";
};
```

for hetzner hosts, use

```nix
boot.loader = {
  systemd-boot.enable = true;
  efi.canTouchEfiVariables = true;
};
```

install

```shell
git clone https://github.com/cullback/dotfiles.git

# Partition and format (destructive!)
nix run github:nix-community/disko -- --mode disko ./hosts/shodan/disko.nix

nixos-install --flake ./hosts#shodan --root /mnt
```
