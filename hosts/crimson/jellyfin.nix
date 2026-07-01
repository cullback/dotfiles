# Jellyfin media server (films + TV), running on crimson where the media lives on
# the frost ZFS pool at /vault/media. We expose it read-only at /srv/media via a bind
# mount (so Jellyfin gets a strictly read-only view of the library) and add the
# jellyfin system user to the `users` group for read access to the cullback:users
# media. Configure the libraries in the web UI on first run, pointing at
# /srv/media/{films,shows}.
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

  # Read-only view of the media for Jellyfin/Navidrome — enforces a read-only view
  # even though the /vault/media source is writable. frost datasets are mounted by
  # zfs-mount.service, so order the bind after it.
  fileSystems."/srv/media" = {
    device = "/vault/media";
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
