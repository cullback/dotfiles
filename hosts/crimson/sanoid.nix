# Automatic ZFS snapshots via sanoid. (Replication is syncoid, added with backups.)
#
# Per the storage plan:
#   admin, repos  -> frequent (active + precious): hourly + daily + weekly
#   state, media, photo -> standard: daily + weekly
#   inbox, dumps, backup -> NOT listed => no snapshots (transient / receive target)
{ ... }:
{
  services.sanoid = {
    enable = true;

    # monthly/yearly pinned to 0 — sanoid's built-in default keeps monthly=6 otherwise.
    templates.frequent = {
      hourly = 24;
      daily = 7;
      weekly = 4;
      monthly = 0;
      yearly = 0;
      autosnap = true;
      autoprune = true;
    };

    templates.standard = {
      hourly = 0;
      daily = 7;
      weekly = 4;
      monthly = 0;
      yearly = 0;
      autosnap = true;
      autoprune = true;
    };

    datasets = {
      "blaze/admin".useTemplate = [ "frequent" ];
      "blaze/repos".useTemplate = [ "frequent" ];
      "blaze/state".useTemplate = [ "standard" ];
      "frost/media".useTemplate = [ "standard" ];
      "frost/photo".useTemplate = [ "standard" ];
    };
  };
}
