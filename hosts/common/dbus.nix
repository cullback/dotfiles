{ ... }:
{
  # Use the classic dbus-daemon instead of dbus-broker.
  #
  # On nixos-26.05, dbus-broker's live reload hangs and hits the 90s systemd
  # timeout during every `nixos-rebuild switch` ("Reload operation timed out"),
  # which stalls the switch and makes it exit 4. dbus-daemon reloads cleanly.
  # NOTE: takes effect after a reboot (the system bus can't hot-swap live).
  services.dbus.implementation = "dbus";
}
