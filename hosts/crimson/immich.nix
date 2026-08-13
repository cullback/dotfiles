# Immich photo server on crimson — the personal photo library.
# https://crimson.taile2df60.ts.net:2283 (tailnet-only, real LetsEncrypt cert).
#
# Deliberately NOT behind caddy.nix and NOT on the LAN. Jellyfin/Navidrome are public
# (geo-fenced) because the worst case is someone watching a film; Immich holds personal
# photos, faces and GPS traces, so it binds loopback and is reached only through
# tailscale serve. Public share links would need funnel or immich-public-proxy — a
# deliberate decision, not a default.
#
# Package is pinned to `unstable` for Immich 3.x — nixpkgs 26.05 ships 2.7.5. This is
# safe because the 26.05 and unstable NixOS modules are functionally identical
# (verified: the only delta is a dropped MPLCONFIGDIR workaround), and the ML server
# is derived from `cfg.package.machine-learning`, so it tracks the same version
# automatically. Re-check on `just update`.
#
# UPGRADES — the sharp edge of tracking unstable.
# Immich applies DB migrations in sequence and does not always support skipping
# versions. A routine `just update` can jump several Immich releases at once; NixOS
# users have had installs broken this way, needing to hunt specific nixpkgs commits to
# step through missed migrations. Immich's nightly pg_dumpall lands in
# /vault/photo/immich/backups and the dataset is snapshotted, so recovery exists — but
# avoiding the break is cheaper. Before bumping: `just immich-preupgrade`, then read
# https://github.com/immich-app/immich/releases between the two versions.
# `nix flake update nixpkgs-unstable` bumps this without touching the rest of the system.
#
# LIBRARY MODEL — managed, not external libraries.
# Immich owns /vault/photo/immich and nothing else. Photos are ingested INTO it, which
# is what makes edit/crop/delete/organize work natively — external libraries silently
# no-op those operations on a read-only mount (immich-app/immich#24064) and merge every
# indexed folder into one timeline regardless.
#
# Immich gets a sandbox rather than the whole vault on purpose: mediaLocation is a
# directory Immich actively manages (six subdirs, including a thumbs/ tree it rewrites
# constantly). The sibling inbox/ and archive/ trees hold irreplaceable data and must
# never be inside something an app runs migration jobs against.
#
#   /vault/photo/immich/    <- this. library/ upload/ profile/ backups/ thumbs/ encoded-video/
#   /vault/photo/inbox/     <- staging; ingest from here, delete the copy after
#   /vault/photo/archive/   <- other people's libraries, deliberately NOT in Immich
#
# FIRST-LOGIN SETTINGS (both default OFF — without them the folder tree never happens):
#   1. Administration -> Settings -> Storage Template -> enable, set
#        {{y}}/{{y}}-{{MM}}-{{dd}}/{{filename}}
#      Otherwise originals land in upload/ under UUID filenames instead of library/.
#   2. Account Settings -> Storage Label -> `ben`
#      Otherwise paths are library/<uuid>/... rather than library/ben/...
# Together these give library/ben/2019/2019-03-15/IMG_1234.heic — a tree that stays
# legible if Immich ever goes away.
{ unstable, ... }:
{
  # Same port number as the backend purely for memorability: Immich binds
  # 127.0.0.1:2283 while serve binds the tailscale IP, so they don't collide.
  local.tailscaleServe."2283" = 2283;

  services.immich = {
    enable = true;
    package = unstable.immich;

    # Loopback only — see the header. Do NOT set host = "0.0.0.0": a daemon bound to
    # 0.0.0.0 on 2283 would shadow tailscale serve on the tailscale IP.
    host = "127.0.0.1";
    port = 2283;
    openFirewall = false;

    # Its own dataset (frost/vault/photo/immich), matching how every other data
    # category under /vault is a dataset rather than a folder. That buys an
    # independent snapshot cadence and, more importantly, independent syncoid
    # replication: the Postgres dumps in backups/ are the irreplaceable part and want
    # sending offsite far more often than the static 145G of inbox/archive beside it.
    # Also allows a quota, so a runaway import can't fill frost.
    #   sudo zfs create -o recordsize=128K frost/vault/photo/immich
    #   sudo chown immich:immich /vault/photo/immich && sudo chmod 0700 /vault/photo/immich
    # recordsize 128K rather than the 1M inherited from frost/vault/photo: this tree is
    # thumbnails and DB dumps, not the large originals that 1M was chosen for.
    #
    # NOT the dataset root: the module ships a tmpfiles rule that chowns mediaLocation
    # to immich and chmods it 0700, so pointing this at /vault/photo would make the
    # whole vault Immich-private and lock cullback out of inbox/ and archive/.
    #
    # thumbs/ and encoded-video/ stay plain folders inside it — regenerable, but
    # written once per asset and then left alone, so snapshots share blocks and cost
    # almost nothing. Not worth two more datasets.
    mediaLocation = "/vault/photo/immich";

    machine-learning.enable = true;
  };

  # The module's own tmpfiles rule is type `e`, which only *adjusts* existing
  # directories. `zfs create` makes the mountpoint root-owned, so without this the
  # first start would hit a store it cannot write. Type `d` creates-or-fixes, which
  # covers both the fresh-dataset case and any later ownership drift.
  systemd.tmpfiles.settings.immich-medialocation."/vault/photo/immich".d = {
    user = "immich";
    group = "immich";
    mode = "0700";
  };

  # NOTE: immich is deliberately NOT in the `users` group. In managed mode it only
  # ever touches its own 0700 store — ingest happens by upload over HTTP, so the
  # service never reads /vault/photo/inbox directly. Adding an external library later
  # would need both that group membership and group-readable perms (`just photo-perms`).

  # Don't start before the frost datasets are mounted. If Immich came up against an
  # unmounted /vault/photo it would find none of its files and start logging every
  # asset as missing. RequiresMountsFor resolves the path to whichever mount backs it,
  # so this keeps working if the dataset layout changes.
  systemd.services.immich-server = {
    after = [ "zfs-mount.service" ];
    unitConfig.RequiresMountsFor = "/vault/photo/immich";
  };
}
