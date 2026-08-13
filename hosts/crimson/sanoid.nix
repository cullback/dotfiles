# Automatic ZFS snapshots via sanoid. (Replication is syncoid, added with backups.)
#
# Per the storage plan (datasets now nested under the /vault root: blaze/vault, frost/vault):
#   vault/admin, vault/repos  -> frequent (active + precious): hourly + daily + weekly
#   vault/photo/immich        -> frequent (active + precious): Immich's albums/faces DB
#   state, vault/media, vault/photo -> standard: daily + weekly
#     (vault/photo is the static side — inbox/ staging and archive/ — while the live
#      library it sits beside, vault/photo/immich, is a child dataset on `frequent`)
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
      # `frequent`, unlike its parent — this is the same "active + precious" case as
      # admin/repos, which is what earns it a separate dataset at all. Immich's albums,
      # faces and people names live only in Postgres, never in the files, so the
      # nightly dumps in immich/backups/ are the payload; a day of hand-curation is
      # real work to redo. The inbox/archive trees beside it are static bulk and stay
      # on `standard`. Hourly is cheap here: imports write new blocks rather than
      # overwriting, so extra snapshots pin little.
      # NOTE: being a child dataset, it is NOT covered by the line above — sanoid only
      # snapshots datasets named here, and `zfs send frost/vault/photo` needs -R to
      # include it. Same caveat applies to any future syncoid job.
      "frost/vault/photo/immich".useTemplate = [ "frequent" ];
    };
  };
}
