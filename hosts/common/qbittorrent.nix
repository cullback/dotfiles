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
        "WebUI\\AuthSubnetWhitelist" = "192.168.1.0/0";
        "WebUI\\AuthSubnetWhitelistEnabled" = true;
      };
    };
  };
}
