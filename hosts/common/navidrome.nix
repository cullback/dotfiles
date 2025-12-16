# Navidrome music server
# Data stored in /var/lib/navidrome (backed up via rclone)
{ ... }:
{
  services.navidrome = {
    enable = true;
    openFirewall = true;
    settings = {
      Address = "127.0.0.1";
      Port = 4533;
      MusicFolder = "/mnt/vault/media/music/primary";
    };
  };

  # Wait for rclone mount before starting navidrome
  systemd.services.navidrome = {
    after = [ "rclone-mount-media.service" ];
    requires = [ "rclone-mount-media.service" ];
  };
}
