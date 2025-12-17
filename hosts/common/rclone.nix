# Rclone storage configuration for storagebox
#
# /mnt/vault/ layout:
#   admin/   - LOCAL, synced via Syncthing, backed up hourly
#   repos/   - LOCAL, backed up hourly (notes/ subfolder synced via Syncthing)
#   state/   - LOCAL, backed up hourly
#   inbox/   - LOCAL, qBittorrent downloads (no backup)
#   media/   - MOUNTED from storagebox:vault/media
#   photo/   - MOUNTED from storagebox:vault/photo
#
# /var/lib/ service data (backed up hourly to storagebox:vault/services/):
#   jellyfin/  - Jellyfin media server state
#   navidrome/ - Navidrome music server state
#
# manually run sync:
# sudo systemctl start rclone-backup-admin rclone-backup-repos rclone-backup-state
# sudo systemctl start rclone-backup-jellyfin rclone-backup-navidrome
{ pkgs, ... }:
let
  vaultPath = "/mnt/vault";
  cachePath = "/var/cache/rclone";

  # Common mount options for rclone FUSE mounts
  mountOpts = ''
    --config /etc/rclone/rclone.conf \
    --vfs-cache-mode full \
    --vfs-cache-max-size 20G \
    --vfs-cache-max-age 168h \
    --vfs-write-back 5s \
    --vfs-read-chunk-size 32M \
    --vfs-read-chunk-size-limit 256M \
    --buffer-size 64M \
    --dir-cache-time 72h \
    --cache-dir ${cachePath} \
    --allow-non-empty \
    --allow-other
  '';

  # Helper to create a mount service (system-level, runs as root)
  mkMountService = name: remote: {
    description = "Rclone mount for ${name}";
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];

    serviceConfig = {
      Type = "notify";
      ExecStartPre = "${pkgs.coreutils}/bin/mkdir -p ${vaultPath}/${name} ${cachePath}";
      ExecStart = "${pkgs.rclone}/bin/rclone mount ${remote} ${vaultPath}/${name} ${mountOpts} --uid 1000 --gid 100";
      ExecStop = "${pkgs.util-linux}/bin/umount ${vaultPath}/${name}";
      Restart = "on-failure";
      RestartSec = "10s";
    };
  };

  # Helper to create a backup service for vault directories
  mkBackupService = name: {
    description = "Rclone backup for ${name}";
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];

    serviceConfig = {
      Type = "oneshot";
      ExecStart = ''
        ${pkgs.rclone}/bin/rclone sync ${vaultPath}/${name} storagebox:vault/${name} \
          --config /etc/rclone/rclone.conf \
          --delete-after
      '';
    };
  };

  # Helper to create a backup service for /var/lib services
  mkVarLibBackupService = name: {
    description = "Rclone backup for /var/lib/${name}";
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];

    serviceConfig = {
      Type = "oneshot";
      ExecStart = ''
        ${pkgs.rclone}/bin/rclone sync /var/lib/${name} storagebox:vault/services/${name} \
          --config /etc/rclone/rclone.conf \
          --delete-after
      '';
    };
  };

  # Helper to create a backup timer
  mkBackupTimer = name: {
    description = "Daily backup timer for ${name}";
    wantedBy = [ "timers.target" ];

    timerConfig = {
      OnCalendar = "*-*-* 05:00:00";
      Persistent = true;
      RandomizedDelaySec = "5m";
    };
  };
in
{
  environment.systemPackages = [ pkgs.rclone ];

  environment.etc."rclone/rclone.conf" = {
    text = ''
      [storagebox]
      type = sftp
      host = u518485.your-storagebox.de
      port = 23
      user = u518485
      key_file = /home/cullback/.ssh/id_ed25519
    '';
    mode = "0600";
  };

  # Ensure vault directories exist with correct permissions
  systemd.tmpfiles.rules = [
    "d /mnt/vault 0755 cullback users -"
    "d /mnt/vault/admin 0755 cullback users -"
    "d /mnt/vault/repos 0755 cullback users -"
    "d /mnt/vault/state 0755 cullback users -"
    "d /mnt/vault/inbox 0755 cullback users -"
    "d /mnt/vault/media 0755 root root -"
    "d /mnt/vault/photo 0755 root root -"
  ];

  # Mount services for large read-heavy directories (system-level)
  systemd.services = {
    rclone-mount-media = mkMountService "media" "storagebox:vault/media";
    rclone-mount-photo = mkMountService "photo" "storagebox:vault/photo";

    # Backup services for local directories
    rclone-backup-admin = mkBackupService "admin";
    rclone-backup-repos = mkBackupService "repos";
    rclone-backup-state = mkBackupService "state";

    # Backup services for /var/lib service data
    rclone-backup-jellyfin = mkVarLibBackupService "jellyfin";
    rclone-backup-navidrome = mkVarLibBackupService "navidrome";
  };

  # Backup timers (system-level)
  systemd.timers = {
    rclone-backup-admin = mkBackupTimer "admin";
    rclone-backup-repos = mkBackupTimer "repos";
    rclone-backup-state = mkBackupTimer "state";
    rclone-backup-jellyfin = mkBackupTimer "jellyfin";
    rclone-backup-navidrome = mkBackupTimer "navidrome";
  };

  # Required for --allow-other flag
  programs.fuse.userAllowOther = true;
}
