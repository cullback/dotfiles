# Automatic ZFS snapshots via sanoid. (Replication is syncoid, added with backups.)
#
# Per the storage plan (datasets now nested under the /vault root: blaze/vault, frost/vault):
#   vault/admin, vault/repos  -> frequent (active + precious): hourly + daily + weekly
#   state, vault/media, vault/photo -> standard: daily + weekly
#     (vault/media now contains the download landing zone at /vault/media/inbox, incl.
#      inbox/.downloading — so in-flight torrents fall under these snapshots too)
#   vault (loose-drop root), vault/inbox (blaze junk drawer), vault/dumps, backup
#     -> NOT listed => no snapshots (transient drop zone / receive target)
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
      "blaze/vault/admin".useTemplate = [ "frequent" ];
      "blaze/vault/repos".useTemplate = [ "frequent" ];
      "blaze/state".useTemplate = [ "standard" ];
      "frost/vault/media".useTemplate = [ "standard" ];
      "frost/vault/photo".useTemplate = [ "standard" ];
    };
  };
}
