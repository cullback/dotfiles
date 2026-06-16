{ pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../common/dev.nix
    ./samba.nix
    ./jellyfin.nix
    ./navidrome.nix
    ../common/caddy.nix
    ../common/tailscale.nix
    ../common/syncthing.nix
    ./wireguard-vpn.nix
    ./qbittorrent.nix
    ./nvme-throttle.nix
  ];

  # Boot
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelPackages = pkgs.linuxPackages_6_12;

  # ZFS storage pool (imported as an extra pool, not via fileSystems)
  boot.supportedFilesystems = [ "zfs" ];
  boot.zfs.extraPools = [ "storage" ];
  # Root is ext4, not ZFS; the storage pool is imported separately, so we do not
  # need to force-import a root pool. (Becomes the default in 26.11.)
  boot.zfs.forceImportRoot = false;
  # generated with: head -c8 /etc/machine-id
  networking.hostId = "5f0559aa";
  services.zfs = {
    autoScrub.enable = true;
    autoScrub.interval = "weekly";
    trim.enable = true;
    # Snapshots protect the personal data on the root dataset (photo/repos/admin/inbox).
    # The big reproducible `media` dataset is excluded via its com.sun:auto-snapshot
    # property (set with: zfs set com.sun:auto-snapshot=false storage/media).
    autoSnapshot = {
      enable = true;
      frequent = 0; # skip the 15-minute snapshots
      hourly = 24;
      daily = 14;
      weekly = 4;
      monthly = 3;
    };
  };

  networking.hostName = "kraken";
  networking.useDHCP = true;

  security.sudo.wheelNeedsPassword = false;

  services.openssh.enable = true;
  programs.ssh.startAgent = true;

  # Public reverse proxy (Caddy, imported above) for movies/music.benburk.ca →
  # Jellyfin (8096) / Navidrome (4533). Only 80/443 are exposed to the WAN via the
  # router's port-forward; ACME (Let's Encrypt) uses port 80 for the HTTP-01 challenge.
  # Everything else stays LAN/Tailscale-only.
  networking.firewall.allowedTCPPorts = [
    80
    443
  ];

  # Syncthing folders — send-receive (kraken is a full read-write peer, taking over
  # atlantix's role). It was initially receive-only during the migration; now that it
  # holds a complete replica it participates fully. Safety net is the ZFS hourly/daily
  # snapshots on the root dataset, which can undo an accidental delete/override.
  services.syncthing.settings.folders = {
    "admin" = {
      path = "/storage/admin";
      type = "sendreceive";
      devices = [
        "atlantix"
        "iphone14"
        "macbook-air"
      ];
    };
    "notes" = {
      path = "/storage/repos/notes";
      type = "sendreceive";
      devices = [
        "atlantix"
        "devy"
        "iphone14"
      ];
    };
  };

  # rclone: migrating data off the Hetzner Storage Box, and future offsite backups.
  environment.systemPackages = [ pkgs.rclone ];

  system.autoUpgrade = {
    enable = true;
    dates = "weekly";
    allowReboot = false;
  };

  system.stateVersion = "25.05";
}
