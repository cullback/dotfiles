{ config, pkgs, ... }:
{
  services.syncthing = {
    enable = true;
    user = "cullback";
    dataDir = "/home/cullback/.local/share/syncthing";
    configDir = "/home/cullback/.config/syncthing";

    guiAddress = "127.0.0.1:8384";

    overrideDevices = true;
    overrideFolders = true;

    settings = {
      gui = {
        insecureSkipHostcheck = true;
      };
    };
  };

  networking.firewall.allowedTCPPorts = [ 22000 ];
  networking.firewall.allowedUDPPorts = [
    22000
    21027
  ];
}
