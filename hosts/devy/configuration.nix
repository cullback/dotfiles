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

  users.users.cullback = {
    isNormalUser = true;
    extraGroups = [ "wheel" ]; # Enable ‘sudo’ for the user.
    packages = with pkgs; [ tree ];
    shell = pkgs.fish;
  };

  environment.systemPackages = with pkgs; [
    git
    gitui
    helix
    just
    qsv
    tree
    yazi
    zellij
    fzf

    # replacements
    bat
    du-dust
    eza
    fd
    ripgrep
    sd

    nixfmt-rfc-style

    # markdown
    marksman
    (python3.withPackages (
      ps: with ps; [
        mdformat
        mdformat-frontmatter
        mdformat-gfm
        mdformat-wikilink
      ]
    ))

    # rust
    rustc
    cargo
  ];

  networking.hostName = "devy";

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

  services.samba = {
    enable = true;
    openFirewall = true;
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

  system.stateVersion = "25.05"; # Did you read the comment?
}
