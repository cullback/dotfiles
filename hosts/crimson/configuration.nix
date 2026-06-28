{ pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./kanata.nix
    ./desktop.nix
  ];

  # Boot
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  # OpenZFS supports kernels up to 7.0, so pin a long-term kernel; the installer's
  # default 7.1.1 is too new for the zfs module to build.
  boot.kernelPackages = pkgs.linuxPackages_6_12;

  # Root is ext4; `tank` (4x28TB RAIDZ2) is the data pool, imported as an extra pool.
  boot.supportedFilesystems = [ "zfs" ];
  boot.zfs.extraPools = [ "tank" "fast" ];
  boot.zfs.forceImportRoot = false;
  # Unique per-host id required by ZFS. Generated with: head -c4 /dev/urandom | od -A none -t x4
  networking.hostId = "8a45121a";

  services.zfs = {
    autoScrub.enable = true;
    autoScrub.interval = "weekly";
    trim.enable = true;
  };

  networking.hostName = "crimson";
  # Networking is managed by NetworkManager (pulled in by the GNOME desktop).

  security.sudo.wheelNeedsPassword = false;

  services.openssh.enable = true;
  programs.ssh.startAgent = true;

  system.stateVersion = "26.05";
}
