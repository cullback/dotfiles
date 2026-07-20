{ ... }:
{
  # Stop a `nixos-rebuild switch` from taking down the desktop via nscd.
  #
  # During activation NixOS stops then restarts nsncd (the NSS caching daemon).
  # If that stop/start happens faster than systemd's default start-rate limit,
  # the unit trips `start-limit-hit` and stays dead. On NixOS most user/group and
  # host lookups route through nscd, so while it's down GDM's user session loses
  # NSS resolution and GNOME Shell crashes mid-switch.
  #
  # Disabling the rate limit lets nscd always come back up after the restart, so
  # an unlucky activation race can't leave it (and the desktop) in a failed state.
  systemd.services.nscd.startLimitIntervalSec = 0;
}
