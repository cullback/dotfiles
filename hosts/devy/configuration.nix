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
    ./services.nix
    ./tailscale.nix
    ../common/sops.nix
    ../common/syncthing.nix
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernel.sysctl."kernel.perf_event_paranoid" = 1;

  networking.hostName = "devy";
  networking.firewall.enable = false;

  security.sudo.wheelNeedsPassword = false;

  services.openssh.enable = true;
  programs.ssh.startAgent = true;

  services.syncthing.settings.folders = {
    "notes" = {
      path = "/home/cullback/repos/notes";
      devices = [
        "atlantix"
        "iphone14"
      ];
    };
  };

  environment.systemPackages = with pkgs; [
    # Utilities
    moreutils
    wget

    # Data Tools
    qsv
    sqlite
    visidata

    # Development Tools
    tokei
    watchexec

    # Terminal Recording
    asciinema-agg
    asciinema_3

    # Web & Browser
    chromium
    single-file-cli

    # Python
    (python313.withPackages (ps: [ ps.requests ]))
    pyright
    ruff

    # AI Assistants
    unstable.claude-code

  ];

  fonts.packages = with pkgs; [
    fira-code
  ];

  system.autoUpgrade = {
    enable = true;
    dates = "weekly";
    allowReboot = false;
  };

  system.stateVersion = "25.05";
}
