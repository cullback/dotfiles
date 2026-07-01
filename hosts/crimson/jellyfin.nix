# Jellyfin media server (films + TV), running on crimson where the media lives on
# the frost ZFS pool. The library mounts under /home/cullback (mode 700), which the
# jellyfin system user can't traverse, so we expose it read-only at /srv/media via a
# bind mount and add jellyfin to the `users` group for read access. Configure the
# libraries in the web UI on first run, pointing at /srv/media/{films,shows}.
# Reachable on the LAN at http://crimson:8096 (openFirewall); also over Tailscale.
{ ... }:
{
  services.jellyfin = {
    enable = true;
    openFirewall = true;
  };

  # Jellyfin runs as its own user (sandboxed); `users` grants read on the
  # cullback:users media files.
  users.users.jellyfin.extraGroups = [ "users" ];

  # Read-only view of the media at a system path the jellyfin user can reach
  # (bypasses the 700 on /home/cullback). frost datasets are mounted by
  # zfs-mount.service, so order the bind after it.
  fileSystems."/srv/media" = {
    device = "/home/cullback/vault/media";
    fsType = "none";
    options = [
      "bind"
      "ro"
      "x-systemd.requires=zfs-mount.service"
      "x-systemd.after=zfs-mount.service"
    ];
  };

  # Don't start Jellyfin until its media is actually mounted.
  systemd.services.jellyfin = {
    after = [ "srv-media.mount" ];
    requires = [ "srv-media.mount" ];
  };
}
