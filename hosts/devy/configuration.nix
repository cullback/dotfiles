{
  config,
  lib,
  pkgs,
  ...
}:

{
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
  ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  programs.fish.enable = true;
  users.defaultUserShell = pkgs.fish;

  users.users.cullback = {
    isNormalUser = true;
    extraGroups = [ "wheel" ]; # Enable sudo for the user.
  };

  environment.variables = {
    NIX_SHELL = "${pkgs.fish}/bin/fish";
  };

  environment.systemPackages = with pkgs; [
    # core tools
    fzf
    git
    gitui
    helix
    just
    yazi
    zellij

    # neat tools
    qsv
    visidata

    # replacements
    bat
    du-dust
    eza
    fd
    ripgrep
    sd

    # markdown
    marksman

    # formatters
    nixfmt-rfc-style
    dprint
    dprint-plugins.dprint-plugin-markdown
    dprint-plugins.dprint-plugin-toml
    dprint-plugins.dprint-plugin-json

    # rust
    rustc
    cargo
    rust-analyzer
  ];

  networking.hostName = "devy";
  networking.firewall.enable = false;

  # Enable the OpenSSH daemon.
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

  system.stateVersion = "25.05"; # Did you read the comment?
}
