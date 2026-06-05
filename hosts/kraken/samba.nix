{ config, ... }:
{
  # kraken's Samba is LAN-exposed (it is the local NAS), unlike atlantix
  # which is Tailscale-only. Shares the local ZFS pool at /storage.
  services.samba = {
    enable = true;
    openFirewall = true;
    settings = {
      global = {
        "workgroup" = "WORKGROUP";
        "server string" = config.networking.hostName;
        "netbios name" = config.networking.hostName;
        "security" = "user";
        # 192.168.2. = LAN, 100. = Tailscale CGNAT range
        "hosts allow" = "192.168.2. 100. 127.0.0.1 localhost";
        "guest account" = "nobody";

        # macOS support
        "vfs objects" = "catia fruit streams_xattr";
        "fruit:metadata" = "stream";
        "fruit:model" = "MacSamba";
        "fruit:veto_appledouble" = "yes";
        "fruit:posix_rename" = "yes";
        "fruit:delete_empty_adfiles" = "yes";
      };
      "storage" = {
        "path" = "/storage";
        "browseable" = "yes";
        "read only" = "no";
        "guest ok" = "no";
        "create mask" = "0644";
        "directory mask" = "0755";
      };
    };
  };
}
