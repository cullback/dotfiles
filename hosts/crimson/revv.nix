# revv — systematic-review extraction visualizer, public at revv.benburk.ca.
#
# Caddy reverse-proxies revv.benburk.ca -> localhost:3100 with auto-TLS (see the
# shared caddy config; DNS is the *.benburk.ca DDNS wildcard). Everything the
# service needs lives under /var/lib/revv, shipped by `just deploy` from the
# working repo (cargo build + rsync of bin/ + static/ + reviews/): the binary at
# bin/revv, web assets in static/, the review corpus in reviews/, and the sqlite
# auth DB (the app won't create it — create_if_missing=false — so it's seeded once
# and left in place). No Nix packaging: the binary is built imperatively on this
# host and dropped into the state dir, so an app update is just `just deploy`, no
# nixos-rebuild. NOTE: signup is open, so anyone who can reach the public URL can
# register and gets editor access to every review.
{ ... }:
let
  port = 3100;
  stateDir = "/var/lib/revv";
in
{
  users.users.revv = {
    isSystemUser = true;
    group = "revv";
    home = stateDir;
  };
  users.groups.revv = { };

  # State dir holds the deploy-shipped binary + assets + corpus + sqlite auth DB.
  systemd.tmpfiles.rules = [
    "d ${stateDir} 0750 revv revv -"
  ];

  systemd.services.revv = {
    description = "revv extraction visualizer";
    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" ];
    serviceConfig = {
      User = "revv";
      Group = "revv";
      # WorkingDirectory holds ./static (served relative to cwd); data paths are
      # absolute so writes land in the state dir.
      WorkingDirectory = stateDir;
      ExecStart = "${stateDir}/bin/revv --bind 127.0.0.1:${toString port} --reviews-dir ${stateDir}/reviews --db-path ${stateDir}/database.sqlite3";
      Restart = "on-failure";
      RestartSec = 2;
    };
  };

  # The public revv.benburk.ca vhost (geo-fenced) lives in caddy.nix alongside
  # movies/music so all three share one gate. This module just runs the service.
}
