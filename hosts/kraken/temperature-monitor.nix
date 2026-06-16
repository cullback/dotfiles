{ pkgs, ... }:

# Persistent temperature logger, born from the 2026-06-15 hard-power-off crashes (drives
# hot to the touch, instant death, nothing in the log). Every 15s it records each NVMe's
# composite/hotspot temp plus the CPU package temp and load average to the systemd journal.
# Because journald is persistent here, after any future crash the final readings survive and
# are retrievable for the dead boot with:  journalctl -u temp-monitor -b -1
#
# Live tail:  journalctl -u temp-monitor -f
let
  intervalSec = 15;
in
{
  systemd.services.temp-monitor = {
    description = "Log NVMe + CPU temperatures to the journal";
    wantedBy = [ "multi-user.target" ];
    # coreutils for cat/basename/readlink/cut/sleep, gawk for the milli-°C math.
    path = [
      pkgs.coreutils
      pkgs.gawk
    ];

    serviceConfig = {
      Restart = "always";
      RestartSec = "5s";
      Nice = 19;
      IOSchedulingClass = "idle";
      ExecStart = pkgs.writeShellScript "temp-monitor" ''
        set -u
        while :; do
          line=""
          for h in /sys/class/hwmon/hwmon*; do
            [ "$(cat "$h/name" 2>/dev/null)" = nvme ] || continue
            dev=$(basename "$(readlink -f "$h/device" 2>/dev/null)")
            comp="?"; hot="?"
            for t in "$h"/temp*_input; do
              [ -e "$t" ] || continue
              lbl=$(cat "''${t%_input}_label" 2>/dev/null)
              v=$(awk '{printf "%.0f",$1/1000}' "$t")
              case "$lbl" in
                Composite) comp=$v ;;
                "Sensor 1") hot=$v ;;
              esac
            done
            line="$line $dev=''${comp}/''${hot}"
          done
          pkg=$(awk '{printf "%.0f",$1/1000}' /sys/class/thermal/thermal_zone1/temp 2>/dev/null)
          load=$(cut -d' ' -f1 /proc/loadavg)
          echo "temps$line cpu=''${pkg:-?} load=$load   (nvme = composite/hotspot °C)"
          sleep ${toString intervalSec}
        done
      '';
    };
  };
}
