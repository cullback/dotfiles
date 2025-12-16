# Jellyfin media server
# Data stored in /var/lib/jellyfin (backed up via rclone)
{ ... }:
{
  services.jellyfin = {
    enable = true;
    openFirewall = true;
  };
}
