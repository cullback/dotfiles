{ config, ... }:

{
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
    user = "cullback";
    dataDir = "/home/cullback/.local/share/syncthing";
    configDir = "/home/cullback/.config/syncthing";

    guiAddress = "0.0.0.0:8384";

    overrideDevices = false;
    overrideFolders = false;

    settings = {
      gui = {
        insecureSkipHostcheck = true;
        insecureAdminAccess = true;
      };
    };
  };
}
