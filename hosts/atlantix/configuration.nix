{
  lib,
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
    ../common/avahi.nix
    ../common/caddy.nix
    ../common/jellyfin.nix
    ../common/navidrome.nix
    ../common/openwebui.nix
    ../common/qbittorrent.nix
    ../common/rclone.nix
    ../common/samba.nix
    ../common/syncthing.nix
    ../common/tailscale.nix
  ];

  services.open-webui.port = lib.mkForce 8001;

  facter.reportPath = ./facter.json;

  boot.loader.grub.enable = true;

  swapDevices = [
    {
      device = "/swapfile";
      size = 4096; # 4GB in MB
    }
  ];

  networking.hostName = "atlantix";
  networking.useDHCP = true;
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [
      22
      80
      443
    ];
  };

  security.sudo.wheelNeedsPassword = false;

  services.openssh.enable = true;

  environment.systemPackages = with pkgs; [
    unstable.claude-code
    unstable.opencode
  ];

  system.autoUpgrade = {
    enable = true;
    dates = "weekly";
    allowReboot = false;
  };

  system.stateVersion = "25.05";
}
