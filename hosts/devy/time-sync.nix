# Clock sync for the UTM VM.
#
# UTM's shared-network NAT silently drops NTP (UDP/123), so
# systemd-timesyncd never gets a packet and the clock never syncs. The
# guest clock also drifts behind real time whenever the Mac host sleeps
# or pauses the VM. TCP does pass the NAT, so instead we pull the time
# from HTTP "Date:" headers over port 80 with htpdate, on a timer.
{ pkgs, lib, ... }:

{
  # timesyncd can't reach NTP through the NAT; disable it so two services
  # aren't both trying to own the clock. mkForce overrides the default-on
  # setting from common/locale.nix.
  services.timesyncd.enable = lib.mkForce false;

  systemd.services.htpdate = {
    description = "Sync system clock from HTTP Date headers (UTM NAT blocks NTP)";
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    serviceConfig = {
      Type = "oneshot";
      # -s set time, -t skip sanity check (post-sleep jumps are large),
      # -4 force IPv4. Multiple hosts so htpdate takes a median.
      ExecStart = "${pkgs.htpdate}/bin/htpdate -s -t -4 www.cloudflare.com www.google.com www.bing.com www.apple.com";
    };
  };

  systemd.timers.htpdate = {
    description = "Periodic HTTP clock sync";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "30s";
      OnUnitActiveSec = "10min";
      Persistent = true;
    };
  };
}
