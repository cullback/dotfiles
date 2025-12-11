{
  pkgs,
  nixpkgs-unstable,
  ...
}:

let
  unstable = import nixpkgs-unstable {
    system = pkgs.system;
    config.allowUnfree = true;
  };
in
{
  imports = [
    ./hardware-configuration.nix
    ../common/boot-grub-bios.nix
    ../common/caddy.nix
    ../common/syncthing.nix
    ../common/tailscale.nix
    ../common/openwebui.nix
  ];

  swapDevices = [
    {
      device = "/swapfile";
      size = 4096; # 4GB in MB
    }
  ];

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
