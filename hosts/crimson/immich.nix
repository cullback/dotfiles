# Immich photo server on crimson — the personal photo library.
# https://crimson.taile2df60.ts.net:5002 (tailnet-only, real LetsEncrypt cert).
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
# avoiding the break is cheaper. Before bumping, snapshot and read the release notes
# between the two versions (https://github.com/immich-app/immich/releases):
#   sudo zfs snapshot frost/vault/photo@immich-pre-upgrade-$(date +%Y%m%d-%H%M%S)
# To recover, restore FILES from that snapshot; do NOT `zfs rollback` — the snapshot
# covers all of /vault/photo, so a rollback would also revert every photo added since.
# The DB is what breaks on a bad upgrade, so restore only that:
#   ls /vault/photo/.zfs/snapshot/immich-pre-upgrade-<stamp>/immich/backups/
# then stop immich-server, restore the dump with pg_restore, and pin the flake back.
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
{ lib, unstable, ... }:
{
  # Immich binds 127.0.0.1:2283; Tailscale Serve exposes it on the contiguous
  # tailnet UI port 5002.
  local.tailscaleServe."5002" = 2283;

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
  #
  # 0750, not upstream's 0700 — see GROUP-READABLE STORE below.
  systemd.tmpfiles.settings.immich-medialocation."/vault/photo/immich".d = {
    user = "immich";
    group = "immich";
    mode = "0750";
  };

  # GROUP-READABLE STORE — a deliberate departure from upstream.
  #
  # Upstream sets `UMask = "0077"` in its shared commonServiceConfig plus a 0700
  # tmpfiles rule, so every file and directory Immich writes is 0600/0700 and nothing
  # outside the service can read the store. That was a fix for early-24.11 installs
  # that created *world*-readable media — a real privacy leak.
  #
  # We relax it to group-readable because the whole justification for accepting
  # "albums/people/hidden live only in Postgres" is that the pixels survive as a
  # legible library/<label>/YYYY/YYYY-MM/ tree if Immich ever goes away. At 0700 that
  # tree is unreadable by the person who owns the photos, which makes the fallback
  # theoretical and also blocks auditing and any non-root backup tool.
  #
  # Group `immich`, NOT `users`: jellyfin is a supplementary member of `users` (see
  # `getent group users`) and is the one service deliberately exposed beyond the
  # tailnet, so `users` would hand the public service read access to every personal
  # photo. Adding cullback to `immich` instead grants exactly one human and nothing
  # else. Still not world-readable — upstream's actual concern is preserved.
  #
  # Trade-off accepted: Immich's app-level privacy gates (hidden assets, the
  # PIN-protected locked folder) stop meaning anything to someone with a shell on
  # this box. They were never a defence against local access anyway.
  #
  # UMask must be mkForce — the module sets it once in an attrset shared by both
  # immich-server and immich-machine-learning, so a plain value collides.
  # 0027 => new files 0640, new directories 0750.
  systemd.services.immich-server.serviceConfig.UMask = lib.mkForce "0027";
  systemd.services.immich-machine-learning.serviceConfig.UMask = lib.mkForce "0027";

  users.users.cullback.extraGroups = [ "immich" ];

  # NOTE: immich is deliberately NOT in the `users` group — the permission grant is
  # one-directional. In managed mode Immich only ever touches its own store; ingest
  # happens by upload over HTTP, so the service never reads /vault/photo/inbox.
  # Adding an external library later would need that group membership plus
  # group-readable perms on the source — macOS-sourced copies land as 0600:
  #   find /vault/photo -path /vault/photo/immich -prune -o -type d -exec chmod 2775 {} +
  #   find /vault/photo -path /vault/photo/immich -prune -o -type f -exec chmod 664 {} +
  # Prune immich/ as above: 2775/664 there would make every photo world-readable.
  #
  # If /vault/photo/immich is ever restored from a snapshot predating the UMask change
  # below, its files come back 0600 — `sudo chmod -R g+rX /vault/photo/immich` fixes it.

  # Don't start before the frost datasets are mounted. If Immich came up against an
  # unmounted /vault/photo it would find none of its files and start logging every
  # asset as missing. RequiresMountsFor resolves the path to whichever mount backs it,
  # so this keeps working if the dataset layout changes.
  systemd.services.immich-server = {
    after = [ "zfs-mount.service" ];
    unitConfig.RequiresMountsFor = "/vault/photo/immich";
  };
}
