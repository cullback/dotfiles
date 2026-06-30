{
  pkgs,
  nixpkgs-unstable,
  ...
}:

let
  unstable = import nixpkgs-unstable {
    system = pkgs.stdenv.hostPlatform.system;
    config.allowUnfree = true;
  };
in
{
  imports = [
    ./hardware-configuration.nix
    ./kanata.nix
    ./desktop.nix
    ./sanoid.nix
    ./syncthing.nix
  ];

  # Boot
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  # OpenZFS supports kernels up to 7.0, so pin a long-term kernel; the installer's
  # default 7.1.1 is too new for the zfs module to build.
  boot.kernelPackages = pkgs.linuxPackages_6_12;

  # Root is ext4. Data pools imported as extra pools: `frost` (4x28TB raidz2, bulk),
  # `blaze` (2x8TB NVMe mirror, hot). Dataset mountpoints are ZFS properties (vault/srv).
  boot.supportedFilesystems = [ "zfs" ];
  boot.zfs.extraPools = [ "frost" "blaze" ];
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

  # claude-code tracks unstable so it stays current (same pattern as atlantix).
  environment.systemPackages = [ unstable.claude-code ];

  system.stateVersion = "26.05";
}
