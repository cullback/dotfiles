# Rclone storage configuration for storagebox
#
# ~/vault/ layout:
#   admin/   - LOCAL, synced via Syncthing, backed up hourly
#   repos/   - LOCAL, backed up hourly (notes/ subfolder synced via Syncthing)
#   state/   - LOCAL, backed up hourly
#   inbox/   - LOCAL, qBittorrent downloads (no backup)
#   media/   - MOUNTED from storagebox:vault/media
#   photo/   - MOUNTED from storagebox:vault/photo
#
# manually run sync
# sudo systemctl start rclone-backup-admin rclone-backup-repos rclone-backup-state
{ pkgs, ... }:
let
  vaultPath = "/home/cullback/vault";
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
    --allow-other
  '';

  # Helper to create a mount service (system-level, runs as root with uid/gid options)
  mkMountService = name: remote: {
    description = "Rclone mount for ${name}";
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];

    serviceConfig = {
      Type = "notify";
      ExecStartPre = "${pkgs.coreutils}/bin/mkdir -p ${vaultPath}/${name} ${cachePath}";
      ExecStart = ''
        ${pkgs.rclone}/bin/rclone mount ${remote} ${vaultPath}/${name} ${mountOpts} \
          --uid 1000 \
          --gid 100
      '';
      ExecStop = "${pkgs.util-linux}/bin/umount ${vaultPath}/${name}";
      Restart = "on-failure";
      RestartSec = "10s";
    };
  };

  # Helper to create a backup service (system-level, runs as root)
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

  # Helper to create a backup timer
  mkBackupTimer = name: {
    description = "Hourly backup timer for ${name}";
    wantedBy = [ "timers.target" ];

    timerConfig = {
      OnCalendar = "hourly";
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

  # Create local vault directories on activation
  system.activationScripts.vaultDirs = ''
    mkdir -p /home/cullback/vault/{admin,repos,state,inbox}
    chown -R cullback:users /home/cullback/vault
  '';

  # Mount services for large read-heavy directories (system-level)
  systemd.services = {
    rclone-mount-media = mkMountService "media" "storagebox:vault/media";
    rclone-mount-photo = mkMountService "photo" "storagebox:vault/photo";

    # Backup services for local directories
    rclone-backup-admin = mkBackupService "admin";
    rclone-backup-repos = mkBackupService "repos";
    rclone-backup-state = mkBackupService "state";
  };

  # Backup timers (system-level)
  systemd.timers = {
    rclone-backup-admin = mkBackupTimer "admin";
    rclone-backup-repos = mkBackupTimer "repos";
    rclone-backup-state = mkBackupTimer "state";
  };

  # Required for --allow-other flag
  programs.fuse.userAllowOther = true;
}
