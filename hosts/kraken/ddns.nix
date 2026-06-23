{ config, pkgs, ... }:

# Dynamic DNS for benburk.ca via Namecheap. The home connection has a dynamic WAN
# IP; when the ISP rotates it, the public A records go stale and movies/music become
# unreachable (this is exactly what happened 2026-06-22). A timer polls the current
# public IP every few minutes and, only when it changes, pushes it to Namecheap's
# DDNS endpoint for the records below.
#
# Requires "Dynamic DNS" enabled on the domain in the Namecheap dashboard, which
# yields the DDNS password stored in sops as `namecheap_ddns`. The endpoint updates
# the source IP of the request (no &ip= needed) for an *existing* host record — it
# will NOT create one, so each name in `hosts` must already exist in Advanced DNS.
#
# Manual run / debug:  systemctl start namecheap-ddns && journalctl -u namecheap-ddns -e
let
  domain = "benburk.ca";
  # Host records to keep current. "@" = bare benburk.ca, "*" = wildcard, which covers
  # movies, music, and any future subdomain. Each MUST exist in Namecheap as type
  # "A + Dynamic DNS Record" — a plain "A Record" returns "A record not Found" from
  # the DDNS endpoint and won't update.
  hosts = [
    "@"
    "*"
  ];
in
{
  sops.secrets.namecheap_ddns = { };

  systemd.services.namecheap-ddns = {
    description = "Update Namecheap DNS records for ${domain} with the current public IP";
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    path = [
      pkgs.curl
      pkgs.coreutils
    ];

    serviceConfig = {
      Type = "oneshot";
      # Persists last-pushed IP across runs so we only call Namecheap on a change.
      StateDirectory = "namecheap-ddns";
      ExecStart = pkgs.writeShellScript "namecheap-ddns" ''
        # -f disables filename globbing so the literal "*" host below isn't expanded
        # against the filesystem by the `for` loop.
        set -euf -o pipefail

        pw=$(tr -d '[:space:]' < ${config.sops.secrets.namecheap_ddns.path})
        state="$STATE_DIRECTORY/last-ip"

        cur=$(curl -fsS --max-time 10 https://api.ipify.org) || {
          echo "could not determine public IP; will retry next tick"
          exit 0
        }

        if [ -f "$state" ] && [ "$(cat "$state")" = "$cur" ]; then
          echo "public IP unchanged ($cur); nothing to do"
          exit 0
        fi

        rc=0
        for host in ${toString hosts}; do
          # Feed the URL via curl's stdin config (-K -) so the password never lands
          # in argv (visible in /proc) or on disk. Namecheap uses the request's
          # source IP since no &ip= is supplied.
          resp=$(printf 'url="https://dynamicdns.park-your-domain.com/update?host=%s&domain=%s&password=%s"\n' \
            "$host" "${domain}" "$pw" | curl -fsS --max-time 15 -K -) || {
            echo "request failed for host=$host"
            rc=1
            continue
          }
          if printf '%s' "$resp" | grep -q '<ErrCount>0</ErrCount>'; then
            echo "updated host=$host -> $cur"
          else
            echo "Namecheap reported an error for host=$host: $resp"
            rc=1
          fi
        done

        # Only cache the IP once every record updated cleanly, so a partial failure
        # keeps retrying on the next tick instead of silently sticking.
        if [ "$rc" -eq 0 ]; then
          printf '%s' "$cur" > "$state"
        fi
        exit $rc
      '';
    };
  };

  systemd.timers.namecheap-ddns = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "2min";
      OnUnitActiveSec = "5min";
      Persistent = true;
    };
  };
}
