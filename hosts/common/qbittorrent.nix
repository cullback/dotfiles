{ ... }:
{
  services.qbittorrent = {
    enable = true;
    user = "cullback";
    openFirewall = true;
    webuiPort = 8080;
    serverConfig = {
      Preferences = {
        "Downloads\\SavePath" = "/mnt/vault/inbox/";
        "WebUI\\AuthSubnetWhitelist" = "192.168.1.0/24, 100.64.0.0/10";
        "WebUI\\AuthSubnetWhitelistEnabled" = true;
      };
    };
  };
}
