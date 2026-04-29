{ pkgs, ... }:

{
  services.qbittorrent = {
    enable = true;
    user = "cullback";
    openFirewall = false;
    webuiPort = 8080;
    serverConfig = {
      Preferences = {
        "Downloads\\SavePath" = "/mnt/vault/inbox/";
        "General\\Locale" = "en";
        "WebUI\\AuthSubnetWhitelist" = "127.0.0.1";
        "WebUI\\AuthSubnetWhitelistEnabled" = true;
        "WebUI\\HostHeaderValidation" = false;
        "WebUI\\CSRFProtection" = false;
      };
    };
  };

  systemd.services.qbittorrent = {
    after = [ "wg-vpn.service" ];
    requires = [ "wg-vpn.service" ];
    serviceConfig.NetworkNamespacePath = "/run/netns/vpn";
  };

  systemd.services.qbittorrent-proxy = {
    description = "qBittorrent Web UI proxy (Tailscale-only)";
    after = [
      "qbittorrent.service"
      "tailscaled.service"
    ];
    requires = [ "qbittorrent.service" ];
    wants = [ "tailscaled.service" ];
    wantedBy = [ "multi-user.target" ];

    serviceConfig = {
      ExecStart = pkgs.writeShellScript "qbittorrent-proxy-start" ''
        for _ in $(seq 1 60); do
          ts_ip=$(${pkgs.tailscale}/bin/tailscale ip -4 2>/dev/null | head -n1)
          if [ -n "$ts_ip" ]; then break; fi
          sleep 1
        done
        if [ -z "$ts_ip" ]; then
          echo "tailscale IP unavailable" >&2
          exit 1
        fi
        exec ${pkgs.socat}/bin/socat \
          "TCP-LISTEN:8080,fork,reuseaddr,bind=$ts_ip" \
          'EXEC:${pkgs.iproute2}/bin/ip netns exec vpn ${pkgs.socat}/bin/socat STDIO TCP\:127.0.0.1\:8080'
      '';
      Restart = "always";
      RestartSec = "5s";
    };
  };
}
