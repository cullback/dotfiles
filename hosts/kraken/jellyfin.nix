# Jellyfin media server (movies + TV). Libraries are configured in the web UI on
# first run, pointing at /storage/media/{Movies,tv-shows}. State in /var/lib/jellyfin.
# Reachable on the LAN at http://kraken:8096 (openFirewall).
{ ... }:
{
  services.jellyfin = {
    enable = true;
    openFirewall = true;
  };

  # Don't start until the local ZFS media dataset is mounted.
  systemd.services.jellyfin = {
    after = [ "zfs-mount.service" ];
    wants = [ "zfs-mount.service" ];
  };
}
