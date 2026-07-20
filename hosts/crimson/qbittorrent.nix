{ pkgs, ... }:

# qBittorrent confined to the "vpn" network namespace (see wireguard-vpn.nix), so all
# its traffic exits via Mullvad and it has no network if the tunnel drops. Completed
# downloads land in /vault/media/inbox (a folder in frost/vault/media, same dataset as
# the library — so `media ingest-*` moves into films/shows/… are instant renames).
# Incomplete downloads stay under inbox/.downloading until they finish. Trade-off: this
# area is now inside a snapshotted dataset (sanoid `standard`), unlike the old
# frost/vault/inbox which was deliberately unsnapshotted.
#
# WebUI at https://crimson.taile2df60.ts.net:8443 — a socat bridge relays the host's
# 127.0.0.1:8443 into the namespace, and tailscale serve fronts that with HTTPS
# (see common/tailscale.nix; the cert is the DNS-rebinding defense). The WebUI port
# must equal the public serve port: qBittorrent's Host validation accepts a
# "name:port" Host only when the port matches its own.
{
  services.qbittorrent = {
    enable = true;
    user = "cullback";
    group = "users";
    openFirewall = false;
    webuiPort = 8443;
    serverConfig = {
      Preferences = {
        "Downloads\\SavePath" = "/vault/media/inbox/";
        "Downloads\\TempPath" = "/vault/media/inbox/.downloading/";
        "Downloads\\TempPathEnabled" = true;
        "General\\Locale" = "en";
        # Requests arrive via the loopback bridge, so they all look like 127.0.0.1
        # and skip auth — fine under the tailnet-is-trusted model now that TLS
        # blocks browser-borne attacks. CSRF protection and Host validation stay at
        # their secure defaults as defense in depth; ServerDomains whitelists the
        # ts.net name that serve forwards in the Host header.
        "WebUI\\AuthSubnetWhitelist" = "127.0.0.1";
        "WebUI\\AuthSubnetWhitelistEnabled" = true;
        "WebUI\\ServerDomains" = "crimson;crimson.taile2df60.ts.net";
      };
    };
  };

  local.tailscaleServe."8443" = 8443;

  systemd.services.qbittorrent = {
    after = [ "wg-vpn.service" ];
    requires = [ "wg-vpn.service" ];
    serviceConfig.NetworkNamespacePath = "/run/netns/vpn";
  };

  # Bridge the WebUI out of the vpn namespace onto the host's loopback, where
  # tailscale serve picks it up. Nothing but tailscaled listens on the tailnet.
  systemd.services.qbittorrent-proxy = {
    description = "qBittorrent WebUI bridge (vpn namespace -> host loopback)";
    after = [ "qbittorrent.service" ];
    requires = [ "qbittorrent.service" ];
    wantedBy = [ "multi-user.target" ];

    serviceConfig = {
      ExecStart = ''
        ${pkgs.socat}/bin/socat \
          TCP-LISTEN:8443,fork,reuseaddr,bind=127.0.0.1 \
          'EXEC:${pkgs.iproute2}/bin/ip netns exec vpn ${pkgs.socat}/bin/socat STDIO TCP\:127.0.0.1\:8443'
      '';
      Restart = "always";
      RestartSec = "5s";
    };
  };
}
