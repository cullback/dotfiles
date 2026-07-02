{
  pkgs,
  unstable,
  ...
}:

{
  imports = [
    ./hardware-configuration.nix
    ./kanata.nix
    ./desktop.nix
    ./voxtype.nix
    ./sanoid.nix
    ./syncthing.nix
    ./samba.nix
    ./jellyfin.nix
    ./navidrome.nix
    ./caddy.nix
    ./revv.nix
    ../common/avahi.nix
    ../common/tailscale.nix
    ./sops.nix
    ./ddns.nix
    # qBittorrent runs inside the wg-vpn network namespace (kill-switch by
    # construction). sops.nix (imported above for DDNS) also decrypts the wg key.
    ./wireguard-vpn.nix
    ./qbittorrent.nix
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
  boot.zfs.extraPools = [
    "frost"
    "blaze"
  ];
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

  # Key-only SSH: authorizedKeys are set in common/users.nix, so refuse passwords
  # entirely and never allow a root login.
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      PermitRootLogin = "no";
    };
  };
  programs.ssh.startAgent = true;

  # claude-code tracks unstable so it stays current.
  # voxtype (voice-to-text) and its input-injection plumbing live in voxtype.nix.
  environment.systemPackages = [
    unstable.claude-code
    pkgs.qsv # CSV toolkit
    pkgs.beets # music library manager / tagger (config in ~/.config/beets)
    pkgs.chromaprint # fpcalc, for beets' chroma acoustic fingerprinting
  ];

  system.stateVersion = "26.05";
}
