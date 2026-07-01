{ ... }:
{
  # crimson is LAN-exposed (local workstation/NAS). Shares /vault, which is a
  # directory with several ZFS datasets (media, photo, repos, ...) mounted under
  # it, so the single share exposes them all. Connect from macOS Finder with
  # Cmd-K -> smb://crimson.local (avahi publishes the .local name).
  services.samba = {
    enable = true;
    openFirewall = true;
    settings = {
      global = {
        "workgroup" = "WORKGROUP";
        "server string" = "crimson";
        "netbios name" = "crimson";
        "security" = "user";
        # 192.168.2. = LAN, 100. = Tailscale CGNAT range
        "hosts allow" = "192.168.2. 100. 127.0.0.1 localhost";
        "guest account" = "nobody";

        # macOS support
        "vfs objects" = "catia fruit streams_xattr";
        "fruit:metadata" = "stream";
        "fruit:model" = "MacSamba";
        "fruit:veto_appledouble" = "yes";
        "fruit:posix_rename" = "yes";
        "fruit:delete_empty_adfiles" = "yes";
      };
      "vault" = {
        "path" = "/vault";
        "browseable" = "yes";
        "read only" = "no";
        "guest ok" = "no";
        "create mask" = "0644";
        "directory mask" = "0755";
        "force user" = "cullback";
        "force group" = "users";
        # Block macOS Finder junk. ._ AppleDouble files are already redirected
        # into xattrs by the fruit/streams_xattr settings above, so they aren't
        # listed here (vetoing them would fight fruit). delete veto files lets
        # Samba remove an otherwise-empty dir even if it only holds these.
        "veto files" = "/.DS_Store/.AppleDouble/.AppleDB/.AppleDesktop/.apdisk/Network Trash Folder/Temporary Items/.TemporaryItems/";
        "delete veto files" = "yes";
      };
    };
  };
}
