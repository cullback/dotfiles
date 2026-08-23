# Public HTTPS reverse proxy for crimson's internet-facing services.
#
# DNS: crimson's namecheap-ddns (ddns.nix) keeps *.benburk.ca pointed at the
# home WAN IP. The Bell Giga Hub forwards TCP 80/443 to crimson; those are the
# only public application ports. Caddy provides automatic HTTPS and sends each
# hostname to a loopback-only backend.
{ ... }:
let
  # Shared edge policy: retain structured access logs, add conservative browser
  # security headers, reject methods a reverse proxy should never need, and stop
  # generic PHP/WordPress probes before they reach an application. Fail2ban below
  # consumes the same logs and blocks repeat scanners at the host firewall.
  secureProxy = upstream: ''
    route {
      header {
        Strict-Transport-Security "max-age=31536000"
        X-Content-Type-Options "nosniff"
        Referrer-Policy "strict-origin-when-cross-origin"
        -Server
      }

      @badMethods method TRACE CONNECT
      respond @badMethods "Method not allowed." 405

      @scanner path_regexp scanner (?i)(?:^|/)(?:\.env(?:$|[./])|\.git(?:$|/)|wp-[^/]*|wordpress(?:$|/)|phpmyadmin(?:$|/)|[^/]*\.php[0-9]*(?:$|/))
      respond @scanner "Not found." 404

      reverse_proxy ${upstream}
    }
  '';
  mkVirtualHost = upstream: {
    # Journald is the single access-log sink; fail2ban reads it directly.
    logFormat = ''
      output stdout
      format json
    '';
    extraConfig = secureProxy upstream;
  };
in
{
  services.caddy = {
    enable = true;
    email = "cullback@fastmail.com";

    virtualHosts."movies.benburk.ca" = mkVirtualHost "127.0.0.1:8096";
    virtualHosts."music.benburk.ca" = mkVirtualHost "127.0.0.1:4533";
    virtualHosts."revv.benburk.ca" = mkVirtualHost "127.0.0.1:3100";
  };

  systemd.services.caddy.serviceConfig = {
    # Caddy only needs one capability to bind 80/443; the NixOS module makes
    # its certificate state writable separately from the read-only host view.
    AmbientCapabilities = [ "CAP_NET_BIND_SERVICE" ];
    CapabilityBoundingSet = [ "CAP_NET_BIND_SERVICE" ];
    LockPersonality = true;
    MemoryDenyWriteExecute = true;
    PrivateTmp = true;
    ProcSubset = "pid";
    ProtectClock = true;
    ProtectControlGroups = true;
    ProtectHostname = true;
    ProtectKernelLogs = true;
    ProtectKernelModules = true;
    ProtectKernelTunables = true;
    ProtectProc = "invisible";
    ProtectSystem = "strict";
    RemoveIPC = true;
    RestrictAddressFamilies = [
      "AF_UNIX"
      "AF_INET"
      "AF_INET6"
    ];
    RestrictNamespaces = true;
    RestrictRealtime = true;
    RestrictSUIDSGID = true;
    SystemCallArchitectures = "native";
    UMask = "0027";
  };

  # Ban repeated application scanners using Caddy's journald JSON. Keep the
  # existing NixOS firewall backend rather than introducing a second firewall
  # stack; fail2ban selects its matching iptables action automatically.
  services.fail2ban = {
    enable = true;
    ignoreIP = [
      "10.0.0.0/8"
      "172.16.0.0/12"
      "192.168.0.0/16"
      "100.64.0.0/10"
      "fd7a:115c:a1e0::/48"
    ];
    bantime-increment = {
      enable = true;
      maxtime = "7d";
    };
    jails.caddy-probes = {
      filter.Definition = {
        failregex = ''(?i)^.*"client_ip":"<HOST>".*"uri":"(?:/+(?:wp-|wordpress|phpmyadmin)[^"]*|/+\.(?:env|git)[^"]*|/[^"]*\.php[0-9]*(?:[/?][^"]*)?)".*$'';
        journalmatch = "_SYSTEMD_UNIT=caddy.service";
      };
      settings = {
        backend = "systemd";
        port = "http,https";
        findtime = "10m";
        maxretry = 3;
        bantime = "1h";
      };
    };
  };

  networking.firewall.allowedTCPPorts = [
    80
    443
  ];
}
