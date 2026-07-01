# revv — systematic-review extraction visualizer, public at revv.benburk.ca.
#
# Caddy reverse-proxies revv.benburk.ca -> localhost:3100 with auto-TLS (see the
# shared caddy config; DNS is the *.benburk.ca DDNS wildcard). The review corpus
# and the sqlite auth DB live in /var/lib/revv, seeded once from the working repo
# (the app won't create the DB — create_if_missing=false — so copy it over). The
# web binary needs no secrets. NOTE: signup is open, so anyone who can reach the
# public URL can register and gets editor access to every review.
{
  revv,
  pkgs,
  ...
}:
let
  revvPkg = revv.packages.${pkgs.stdenv.hostPlatform.system}.default;
  port = 3100;
in
{
  users.users.revv = {
    isSystemUser = true;
    group = "revv";
    home = "/var/lib/revv";
  };
  users.groups.revv = { };

  # State dir for the review corpus + sqlite auth DB (seeded manually once).
  systemd.tmpfiles.rules = [
    "d /var/lib/revv 0750 revv revv -"
  ];

  systemd.services.revv = {
    description = "revv extraction visualizer";
    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" ];
    serviceConfig = {
      User = "revv";
      Group = "revv";
      # WorkingDirectory holds ./static (served relative to cwd); data paths are
      # absolute so writes land in the state dir, not the read-only store.
      WorkingDirectory = "${revvPkg}/share/revv";
      ExecStart = "${revvPkg}/bin/revv --bind 127.0.0.1:${toString port} --reviews-dir /var/lib/revv/reviews --db-path /var/lib/revv/database.sqlite3";
      Restart = "on-failure";
      RestartSec = 2;
    };
  };

  services.caddy.virtualHosts."revv.benburk.ca".extraConfig = ''
    reverse_proxy localhost:${toString port}
  '';
}
