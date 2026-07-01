# Public HTTPS reverse proxy (Caddy) for movies.benburk.ca -> Jellyfin on crimson.
#
# DNS: crimson's namecheap-ddns (ddns.nix) keeps *.benburk.ca pointed at the home WAN IP, so
# movies.benburk.ca already resolves to this house. For it to reach crimson the
# Bell Giga Hub must forward TCP 80/443 -> 192.168.2.31 (crimson's LAN IP; reserve
# it in the modem's DHCP table so it doesn't drift). Port 80 is also required for
# Caddy's Let's Encrypt HTTP-01 challenge. Only 80/443 are public; Jellyfin's 8096
# stays LAN/Tailscale-only.
#
# music.benburk.ca is intentionally omitted - Navidrome isn't on crimson yet.
{ ... }:
{
  services.caddy = {
    enable = true;
    email = "cullback@fastmail.com";
    virtualHosts."movies.benburk.ca".extraConfig = ''
      reverse_proxy localhost:8096
    '';
  };

  networking.firewall.allowedTCPPorts = [
    80
    443
  ];
}
