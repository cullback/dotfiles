{ lib, ... }:

# Event layer for the media pipeline: qbittorrent.nix's AutoRun hook drops a
# marker into /vault/media/inbox/.queue when a torrent finishes; the path unit
# here fires a oneshot that clears the queue and runs `media ingest` (snapshot →
# headless agent over the inbox → qbit prune) as cullback. Markers are removed
# BEFORE the run: anything finishing mid-run leaves a fresh marker, and systemd
# re-fires the path unit once the service exits — nothing is lost, and systemd
# itself serializes runs (a service never starts twice concurrently).
{
  systemd.tmpfiles.rules = [
    "d /vault/media/inbox/.queue 0755 cullback users -"
  ];

  systemd.paths.media-ingest = {
    description = "Watch the media inbox queue for finished downloads";
    wantedBy = [ "multi-user.target" ];
    pathConfig = {
      DirectoryNotEmpty = "/vault/media/inbox/.queue";
    };
  };

  systemd.services.media-ingest = {
    description = "Ingest agent run over the media inbox";
    environment = {
      HOME = "/home/cullback"; # claude credentials + config
      # Service PATH omits the system profile by default, but the chain needs
      # zfs (snapshot), nix (`just ingest` runtime), claude, and whatever the
      # agent's Bash tool reaches for — give it what an interactive shell has.
      # mkForce: replace the unit-default base-utils PATH (the system profile
      # carries all of those anyway).
      PATH = lib.mkForce "/run/wrappers/bin:/etc/profiles/per-user/cullback/bin:/home/cullback/.nix-profile/bin:/run/current-system/sw/bin";
    };
    serviceConfig = {
      Type = "oneshot";
      User = "cullback";
      Group = "users";
      WorkingDirectory = "/vault/media";
      # The agent run is minutes-long by design; never let systemd kill it.
      TimeoutStartSec = "infinity";
    };
    script = ''
      rm -f /vault/media/inbox/.queue/*
      exec just ingest
    '';
  };
}
