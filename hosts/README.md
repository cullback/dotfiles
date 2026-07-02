# Hosts

NixOS machines are defined by the flake in this directory. macOS is managed
separately with Homebrew (see `macos/`).

## crimson

Desktop workstation and home server (AMD, x86_64). GNOME on Wayland, ext4
root, ZFS data pools (`frost` 4x28TB raidz2 for bulk, `blaze` 2x8TB NVMe
mirror for hot data) mounted under `/vault`. Runs the household services:
Jellyfin, Navidrome, Syncthing, Samba, qBittorrent (inside a Mullvad
WireGuard network namespace), and a geo-fenced Caddy reverse proxy for
`*.benburk.ca` (DNS kept current by a Namecheap DDNS timer).

Rebuild from the repo root with `just nix-rebuild`.

## Installing a new NixOS host

1. Boot the installer, partition and format, then generate a hardware config:
   `nixos-generate-config --root /mnt`.
2. Create `hosts/<hostname>/` (crimson is the reference), add the host to
   `flake.nix`, and copy in the generated `hardware-configuration.nix`.
3. Bootstrap secrets for the host (next section).
4. Install: `nixos-install --flake ./hosts#<hostname> --root /mnt`.

## Secrets (sops-nix)

Secrets live in `secrets/<host>.yaml`, encrypted with age to the host's SSH
ed25519 host key — so a host's secrets can only be created and decrypted on
that host. Bootstrap for a new host:

1. Get the host's age recipient from its public host key:

   ```sh
   ssh-to-age < /etc/ssh/ssh_host_ed25519_key.pub
   ```

2. Add it under `keys:` in `secrets/.sops.yaml` with a creation rule for
   `<host>.yaml`.

3. Create or edit the secrets file on that host (sops needs the age private
   key, derived from the SSH host key):

   ```sh
   SOPS_AGE_KEY=$(sudo ssh-to-age -private-key -i /etc/ssh/ssh_host_ed25519_key) \
     sops secrets/<host>.yaml
   ```

4. Declare the secrets in the host's `sops.nix` and reference them with
   `config.sops.secrets.<name>.path`.

The user login password hash (`mkpasswd -m sha-512`) must be stored with
`neededForUsers = true` so it is decrypted before user activation
(see `crimson/sops.nix` and `common/users.nix`).
