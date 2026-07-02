# Public HTTPS reverse proxy (Caddy) for crimson's services, geo-fenced to Canada.
#
# DNS: crimson's namecheap-ddns (ddns.nix) keeps *.benburk.ca pointed at the home WAN IP, so
# {movies,music,revv}.benburk.ca already resolve to this house. For it to reach crimson the
# Bell Giga Hub must forward TCP 80/443 -> 192.168.2.31 (crimson's LAN IP; reserve
# it in the modem's DHCP table so it doesn't drift). Port 80 is also required for
# Caddy's Let's Encrypt HTTP-01 challenge. Only 80/443 are public; Jellyfin (8096),
# Navidrome (4533), revv (3100) are otherwise LAN/Tailscale-only.
#
# Geo-blocking: Caddy is rebuilt with the maxmind_geolocation matcher and every
# public vhost serves only Canadian IPs (plus LAN/Tailscale, which are always
# allowed so we can't lock ourselves out). Uses the free DB-IP country-lite
# database (no MaxMind license needed), pinned into the nix store so a failed
# download can never leave Caddy without a db at runtime. Bump the month + hash
# periodically to refresh; tailnet users reach services directly regardless.
{ pkgs, ... }:
let
  # Free DB-IP country database (CC-BY 4.0), gunzipped into the store.
  geoipDb =
    let
      gz = pkgs.fetchurl {
        url = "https://download.db-ip.com/free/dbip-country-lite-2026-07.mmdb.gz";
        sha256 = "0zsh41jflxhwdw7m5044l9z5j0yzmx1wdb185q1r670wmnlmg74q";
      };
    in
    pkgs.runCommand "dbip-country-lite.mmdb" { } ''
      ${pkgs.gzip}/bin/gunzip -c ${gz} > $out
    '';

  # A geo-fenced reverse proxy to `upstream`: serve CA + LAN/Tailscale, else 403.
  # `route` forces top-to-bottom evaluation so the deny short-circuits the proxy.
  #
  # Access logging is on (to stdout -> journald) so we can see every request's
  # status + client_ip — Caddy only emits error logs by default, which is why
  # 403 geo-denials were invisible. Inspect with:
  #   journalctl -u caddy -o cat | grep '"status":403'
  # then look up the offending client_ip against the mmdb to see why it was denied.
  geoGate = upstream: ''
    log {
      output stdout
      format json
    }
    route {
      @denied {
        not remote_ip 127.0.0.1/8 ::1 10.0.0.0/8 172.16.0.0/12 192.168.0.0/16 100.64.0.0/10 fd7a:115c:a1e0::/48
        not maxmind_geolocation {
          db_path "${geoipDb}"
          # CA + PM: iCloud Private Relay tunnels Canadian users out through Fastly
          # egress nodes that the DB-IP database maps to PM (Saint-Pierre-et-Miquelon,
          # the French islands off Newfoundland), not CA — so CA-only 403'd real
          # Canadian visitors. PM is tiny (~6k pop.), so allowing it is low risk.
          # US is deliberately NOT included (would open the fence to all of the US);
          # if relay users still get 403s from US-mapped nodes, revisit (logs will show).
          allow_countries CA PM
        }
      }
      respond @denied "Not available in your region." 403
      reverse_proxy ${upstream}
    }
  '';
in
{
  services.caddy = {
    enable = true;
    email = "cullback@fastmail.com";
    # Rebuild Caddy with the maxmind geolocation matcher.
    package = pkgs.caddy.withPlugins {
      plugins = [ "github.com/porech/caddy-maxmind-geolocation@v1.0.3" ];
      hash = "sha256-uUYds3PGZ4b/MR81ZzzodRhnr38WAwQqmRvOzeo0bXU=";
    };

    virtualHosts."movies.benburk.ca".extraConfig = geoGate "localhost:8096";
    virtualHosts."music.benburk.ca".extraConfig = geoGate "localhost:4533";
    virtualHosts."revv.benburk.ca".extraConfig = geoGate "localhost:3100";
  };

  networking.firewall.allowedTCPPorts = [
    80
    443
  ];
}
