# Tailscale + a declarative wrapper around `tailscale serve`.
#
# `local.tailscaleServe` maps an HTTPS port to a localhost backend port; each entry
# is served tailnet-only at https://<host>.<tailnet>.ts.net:<port> with a real
# LetsEncrypt cert (requires MagicDNS + HTTPS certs enabled in the admin console).
# This is the standard front door for web UIs that shouldn't carry their own auth
# under the tailnet-is-trusted model: the TLS cert is the DNS-rebinding defense —
# a browser lured to a rebound domain fails certificate validation — so backends
# can bind plain HTTP on 127.0.0.1 with app-level auth/host-checks off.
# NOTE: tailscale serve only offers HTTPS on ports 443, 8443 and 10000, and the
# cert pins the URL to the full ts.net name (short names / raw IPs won't validate).
# A host daemon bound to 0.0.0.0 on the same port shadows serve on the tailscale
# IP (Caddy does this on crimson's 443), so pick ports no other service binds.
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.local.tailscaleServe;
in
{
  options.local.tailscaleServe = lib.mkOption {
    type = lib.types.attrsOf lib.types.port;
    default = { };
    example = {
      "443" = 8384;
    };
    description = "HTTPS port (443, 8443 or 10000) -> localhost backend port to expose on the tailnet.";
  };

  config = {
    services.tailscale.enable = true;

    networking.firewall = {
      trustedInterfaces = [ "tailscale0" ];
      allowedUDPPorts = [ config.services.tailscale.port ];
    };

    # serve config persists in tailscaled's state, so re-assert the declared set on
    # every boot/activation; the reset drops entries that are no longer declared.
    systemd.services.tailscale-serve = lib.mkIf (cfg != { }) {
      description = "Declare tailscale serve entries";
      after = [ "tailscaled.service" ];
      requires = [ "tailscaled.service" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
      script = ''
        for _ in $(seq 1 60); do
          if ${pkgs.tailscale}/bin/tailscale status > /dev/null 2>&1; then break; fi
          sleep 1
        done
        ${pkgs.tailscale}/bin/tailscale serve reset
        ${lib.concatStringsSep "\n" (
          lib.mapAttrsToList (
            httpsPort: backendPort:
            "${pkgs.tailscale}/bin/tailscale serve --bg --https=${httpsPort} http://127.0.0.1:${toString backendPort}"
          ) cfg
        )}
      '';
    };
  };
}
