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
        atlantix = {
          id = "KE3E6GT-HIZQYTR-AUKPQJD-RLEPSVL-NMUX3NW-HTH6G22-PXRHCFC-RWEE3AZ";
        };
        devy = {
          id = "3KTU3QZ-7MUVXUU-WHG2FII-5XRZDEM-72LKOO3-GRYU6QZ-JWSTJH4-FTYSCQK";
        };
        iphone14 = {
          id = "P7D6TDJ-EM4PIG6-W3AHLYZ-VVSQVME-7AOS5E3-7FPAPCM-52GAQZO-XAVKCQ7";
        };
        macbook-air = {
          id = "O2QNTQH-2XGCZ6N-7TP7QXA-E22L6IG-J3EPPTQ-R7LMVSX-KKSPSSI-FKSHJAB";
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
