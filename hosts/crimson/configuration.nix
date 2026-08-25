{
  pkgs,
  unstable,
  deemix,
  ...
}:

let
  # Upstream's committed pnpmDeps hash is stale — they ship releases via
  # `pnpm make`, not the flake, so fetchPnpmDeps' pinned hash drifted from the
  # lockfile. The hash below is what fetchPnpmDeps actually produces for the
  # pinned lockfile. Re-verify (and drop this override) on `nix flake update`.
  deemix-cli = (deemix.packages.${pkgs.stdenv.hostPlatform.system}.cli).overrideAttrs (old: {
    pnpmDeps = pkgs.fetchPnpmDeps {
      pname = old.pname;
      version = old.version;
      src = old.src;
      fetcherVersion = 3;
      hash = "sha256-uvi7hudXj6yaaRM7q9iWpa2E/SKUvXnjTWZlzhcEgFQ=";
    };
  });
in
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
    ./immich.nix
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
    ./media-ingest.nix
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

  # Tailnet-only scratch space for temporary local web apps. Each public port
  # forwards to the same loopback port, so an app bound to 127.0.0.1:3000 is
  # available at https://crimson.taile2df60.ts.net:3000/ (and likewise :3001–:3050).
  # These are declared because tailscale-serve resets its entire persisted config
  # on each activation; ad-hoc `tailscale serve` rules would otherwise disappear.
  local.tailscaleServe = builtins.listToAttrs (
    map (port: {
      name = toString port;
      value = port;
    }) (builtins.genList (offset: 3000 + offset) 51)
  );

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

  # gitui uses libgit2/libssh2 rather than OpenSSH, so it cannot fall back to
  # ~/.ssh/id_ed25519 directly. Load the key into the managed agent at login.
  systemd.user.services.ssh-add-key = {
    description = "Load the default SSH key into ssh-agent";
    wantedBy = [ "default.target" ];
    requires = [ "ssh-agent.service" ];
    after = [ "ssh-agent.service" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.openssh}/bin/ssh-add %h/.ssh/id_ed25519";
    };
  };

  # claude-code and pi track unstable so they stay current. pi picks up the
  # OpenRouter key from OPENROUTER_API_KEY, already exported in sops.nix.
  # voxtype (voice-to-text) and its input-injection plumbing live in voxtype.nix.
  environment.systemPackages = [
    unstable.claude-code
    unstable.pi-coding-agent
    pkgs.beets # music library manager / tagger (config in ~/.config/beets)
    pkgs.chromaprint # fpcalc, for beets' chroma acoustic fingerprinting
    deemix-cli # Deezer downloader CLI (bambanah monorepo, pnpmDeps hash patched)
  ];

  system.stateVersion = "26.05";
}
