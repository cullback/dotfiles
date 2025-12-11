{ config, pkgs, ... }:
{
  services.syncthing = {
    enable = true;
    user = "cullback";
    dataDir = "/home/cullback/.local/share/syncthing";
    configDir = "/home/cullback/.config/syncthing";

    guiAddress = "0.0.0.0:8384";

    overrideDevices = true;
    overrideFolders = true;

    settings = {
      devices = {
        iphone14 = {
          id = "P7D6TDJ-EM4PIG6-W3AHLYZ-VVSQVME-7AOS5E3-7FPAPCM-52GAQZO-XAVKCQ7";
        };
        macbook-air = {
          id = "O2QNTQH-2XGCZ6N-7TP7QXA-E22L6IG-J3EPPTQ-R7LMVSX-KKSPSSI-FKSHJAB";
        };
      };
      folders = {
        "admin" = {
          path = "/home/cullback/vault/admin";
          devices = [
            "iphone14"
            "macbook-air"
          ];
        };
        "notes" = {
          path = "/home/cullback/vault/repos/notes";
          devices = [
            "iphone14"
          ];
        };
      };
      gui = {
        insecureSkipHostcheck = true;
        insecureAdminAccess = true;
      };
    };
  };

  networking.firewall.allowedTCPPorts = [ 22000 ];
  networking.firewall.allowedUDPPorts = [
    22000
    21027
  ];
}
