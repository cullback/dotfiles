{ lib, ... }:
{
  # Work around dbus-broker v37 (nixpkgs 26.05) hanging every `nixos-rebuild switch`.
  #
  # v37 moved its reload to systemd's `notify-reload` protocol, but the reload
  # handshake never signals completion, so `systemctl reload dbus-broker` blocks
  # for the full 90s TimeoutStartSec, gets killed, and the switch exits 4.
  # NixOS triggers that reload on every switch (the module sets reloadIfChanged).
  #
  # The system bus can't be safely live-reloaded/restarted anyway — policy changes
  # apply on reboot — so we tell NixOS to do nothing to it on change. This keeps the
  # modern dbus-broker (no revert to dbus-daemon) and removes the 90s stall.
  # Verify with `nixos-rebuild dry-activate`: dbus-broker must appear in NEITHER the
  # "would reload" nor "would restart" lists.
  systemd.services.dbus-broker = {
    reloadIfChanged = lib.mkForce false;
    restartIfChanged = lib.mkForce false;
  };

  # Same hang affects the per-user dbus-broker ("user activation for cullback failed").
  systemd.user.services.dbus-broker = {
    reloadIfChanged = lib.mkForce false;
    restartIfChanged = lib.mkForce false;
  };
}
