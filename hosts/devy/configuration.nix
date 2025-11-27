{
  config,
  lib,
  pkgs,
  ...
}:

let
  unstable = import <nixpkgs-unstable> { config.allowUnfree = true; };
in
{
  # 1. Imports
  imports = [
    ./hardware-configuration.nix
  ];

  # 2. Boot configuration
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # 3. Networking
  networking.hostName = "devy";
  networking.firewall.enable = false;

  # 4. Localization
  time.timeZone = "America/Toronto"; # Changed to your location
  i18n.defaultLocale = "en_US.UTF-8";

  # 5. Users
  users.defaultUserShell = pkgs.fish;
  users.users.cullback = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGUvNZI9LHiN7RmqBxDt5wiawgec9BHAAkAtMidrf5/b cullback@fastmail.com"
    ];
  };

  # 6. Security

  # 7. Services
  services.openssh.enable = true;

  services.samba = {
    enable = true;
    settings = {
      global = {
        "workgroup" = "WORKGROUP";
        "server string" = config.networking.hostName;
        "netbios name" = config.networking.hostName;
        "security" = "user";
        "hosts allow" = "192.168.64. 192.168.1. 127.0.0.1 localhost";
        "guest account" = "nobody";

        # macOS support
        "vfs objects" = "catia fruit streams_xattr";
        "fruit:metadata" = "stream";
        "fruit:model" = "MacSamba";
        "fruit:veto_appledouble" = "yes";
        "fruit:posix_rename" = "yes";
        "fruit:delete_empty_adfiles" = "yes";
      };
      "${config.networking.hostName}" = {
        "path" = "/home/cullback";
        "browseable" = "yes";
        "read only" = "no";
        "guest ok" = "no";
        "create mask" = "0644";
        "directory mask" = "0755";
      };
    };
  };

  services.avahi = {
    enable = true;
    nssmdns4 = true;
    publish = {
      enable = true;
      addresses = true;
      workstation = true;
    };
  };

  services.syncthing = {
    enable = true;
    guiAddress = "0.0.0.0:8384";
    user = "cullback";
    configDir = "/home/cullback/.config/syncthing";
    settings = {
      devices = {
        "iphone" = {
          id = "P7D6TDJ-EM4PIG6-W3AHLYZ-VVSQVME-7AOS5E3-7FPAPCM-52GAQZO-XAVKCQ7";
        };
      };

      folders = {
        "repos" = {
          path = "/home/cullback/repos";
          devices = [ "iphone" ];
        };
      };
    };
  };

  # 8. Programs
  programs.fish.enable = true;

  # 9. Environment
  nixpkgs.config.allowUnfree = true;
  environment.systemPackages = with pkgs; [
    # system
    parted

    # core tools
    moreutils
    wget
    fzf
    git
    gitui
    helix
    just
    yazi
    zellij
    starship

    # replacements
    bat
    du-dust
    eza
    fd
    ripgrep
    sd
    delta # better diff tool

    # neat tools
    qsv # csv wrangling
    visidata
    sqlite
    tokei # line count by language
    watchexec # rerun command on changes
    single-file-cli
    chromium

    # markdown
    marksman

    # formatters
    nixfmt-rfc-style
    dprint
    dprint-plugins.dprint-plugin-markdown
    dprint-plugins.dprint-plugin-toml
    dprint-plugins.dprint-plugin-json

    # python
    python313
    pyright
    ruff

    unstable.claude-code
    unstable.opencode
  ];

  # 10. Nix settings
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };

  # 11. State version (always last)
  system.stateVersion = "25.05";
}
