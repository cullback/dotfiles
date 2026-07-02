{ pkgs, ... }:

# qBittorrent confined to the "vpn" network namespace (see wireguard-vpn.nix), so all
# its traffic exits via Mullvad and it has no network if the tunnel drops. The WebUI is
# reachable only over Tailscale, via a socat proxy that bridges into the namespace.
# Downloads land in /vault/inbox (frost — transient, deliberately unsnapshotted).
{
  services.qbittorrent = {
    enable = true;
    user = "cullback";
    group = "users";
    openFirewall = false;
    webuiPort = 8080;
    serverConfig = {
      Preferences = {
        "Downloads\\SavePath" = "/vault/inbox/";
        "General\\Locale" = "en";
        # Requests arrive via the socat proxy, so they all look like 127.0.0.1 and
        # skip auth — fine under the tailnet-is-trusted model, but it means the WebUI
        # must defend itself against requests a browser was tricked into sending
        # (DNS rebinding / CSRF). CSRF protection and Host validation therefore stay
        # at their secure defaults; ServerDomains whitelists the tailnet names, since
        # the Host header won't match qBittorrent's in-namespace 127.0.0.1 bind.
        # NOTE: browse via http://crimson:8080 (MagicDNS) — qBittorrent only accepts
        # an IP-literal Host if it equals the bind address, so the raw tailscale IP
        # gets 401 by design (listing it in ServerDomains has no effect).
        "WebUI\\AuthSubnetWhitelist" = "127.0.0.1";
        "WebUI\\AuthSubnetWhitelistEnabled" = true;
        "WebUI\\ServerDomains" = "crimson;crimson.taile2df60.ts.net";
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
