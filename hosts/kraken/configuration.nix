{ pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./dev.nix
    ./samba.nix
    ./jellyfin.nix
    ./navidrome.nix
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
  };

  networking.hostName = "kraken";
  networking.useDHCP = true;

  security.sudo.wheelNeedsPassword = false;

  services.openssh.enable = true;
  programs.ssh.startAgent = true;

  system.autoUpgrade = {
    enable = true;
    dates = "weekly";
    allowReboot = false;
  };

  system.stateVersion = "25.05";
}
