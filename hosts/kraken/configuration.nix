{ pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./dev.nix
    ./samba.nix
    ./jellyfin.nix
    ./navidrome.nix
    ../common/tailscale.nix
    ../common/syncthing.nix
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

  # Syncthing folders — receive-only on kraken. As a replica/server it never edits
  # these by hand, so it can only pull from the mesh, never push deletes/overrides.
  # (Protects the important `admin` folder; also ZFS-snapshotted on the root dataset.)
  services.syncthing.settings.folders = {
    "admin" = {
      path = "/storage/admin";
      type = "receiveonly";
      devices = [
        "atlantix"
        "iphone14"
        "macbook-air"
      ];
    };
    "notes" = {
      path = "/storage/repos/notes";
      type = "receiveonly";
      devices = [
        "atlantix"
        "devy"
        "iphone14"
      ];
    };
  };

  system.autoUpgrade = {
    enable = true;
    dates = "weekly";
    allowReboot = false;
  };

  system.stateVersion = "25.05";
}
