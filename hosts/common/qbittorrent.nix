{ pkgs, ... }:

{
  services.qbittorrent = {
    enable = true;
    user = "cullback";
    openFirewall = true;
    webuiPort = 8080;
    serverConfig = {
      Preferences = {
        "Downloads\\SavePath" = "/mnt/vault/inbox/";
        "General\\Locale" = "en";
        "WebUI\\AuthSubnetWhitelist" = "192.168.1.0/24, 100.64.0.0/10, 127.0.0.1";
        "WebUI\\AuthSubnetWhitelistEnabled" = true;
      };
    };
  };

  systemd.services.qbittorrent = {
    after = [ "wg-vpn.service" ];
    requires = [ "wg-vpn.service" ];
    serviceConfig.NetworkNamespacePath = "/run/netns/vpn";
  };

  systemd.services.qbittorrent-proxy = {
    description = "qBittorrent Web UI proxy";
    after = [ "qbittorrent.service" ];
    requires = [ "qbittorrent.service" ];
    wantedBy = [ "multi-user.target" ];

    serviceConfig = {
      ExecStart = "${pkgs.socat}/bin/socat TCP-LISTEN:8080,fork,reuseaddr EXEC:'${pkgs.iproute2}/bin/ip netns exec vpn ${pkgs.socat}/bin/socat STDIO TCP\\:127.0.0.1\\:8080'";
      Restart = "always";
    };
  };
}
