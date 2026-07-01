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
        devy = {
          id = "3KTU3QZ-7MUVXUU-WHG2FII-5XRZDEM-72LKOO3-GRYU6QZ-JWSTJH4-FTYSCQK";
        };
        iphone14 = {
          id = "P7D6TDJ-EM4PIG6-W3AHLYZ-VVSQVME-7AOS5E3-7FPAPCM-52GAQZO-XAVKCQ7";
        };
        macbook-air = {
          id = "O2QNTQH-2XGCZ6N-7TP7QXA-E22L6IG-J3EPPTQ-R7LMVSX-KKSPSSI-FKSHJAB";
        };
        crimson = {
          id = "DZAECZQ-DXCQMV7-IF7LPCM-E3DOTB3-6OQGF5B-KY2O765-SUIP2TY-55COWQ7";
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
