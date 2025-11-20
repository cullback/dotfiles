{ config, pkgs, ... }:

{
  # 1. Imports
  imports = [
    ./hardware-configuration.nix
  ];

  # 2. Boot configuration
  boot.loader.grub = {
    enable = true;
    device = "/dev/vda"; # or /dev/vda
  };

  # 3. Networking
  networking.hostName = "shodan";
  networking.useDHCP = true;
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [
      22
      80
      443
    ];
  };

  # 4. Localization
  time.timeZone = "America/New_York";
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
  security.sudo.wheelNeedsPassword = false;

  # 7. Services
  services.openssh = {
    enable = true;
  };

  # 8. Programs
  programs.fish.enable = true;

  # 9. Environment
  environment.systemPackages = with pkgs; [
    # system
    parted

    # core tools
    git
    helix
    yazi
    zellij
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

  # Auto-upgrade
  system.autoUpgrade = {
    enable = true;
    dates = "weekly";
    allowReboot = false; # Set to true if you want automatic reboots
  };

  # 11. State version (always last)
  system.stateVersion = "25.05";
}
