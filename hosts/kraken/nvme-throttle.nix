{ pkgs, ... }:

# The four WD_BLACK SN850X drives (the `storage` ZFS pool) plus the Samsung 990 EVO Plus
# root drive run very hot in this small chassis. Under sustained Jellyfin transcode load
# the box hard-powered-off repeatedly (2026-06-15): hot to the touch, nothing logged, and
# climbing SMART "Unsafe Shutdowns" — consistent with heat overwhelming the power delivery
# (the SN850X are among the hottest consumer NVMe, ~7W each; the EVO Plus root drive logged
# minutes of *critical* thermal throttling).
#
# This lowers each drive's Host Controlled Thermal Management (HCTM) thresholds so they
# self-throttle earlier — light throttle at 70°C, heavy at 80°C (composite) — cutting both
# the heat dumped into the case and peak power draw. It's a mitigation, not a cure; proper
# airflow/heatsinks and PSU headroom are still the real fix.
#
# HCTM is volatile (resets on every power-cycle), so this re-applies it on each boot.
let
  tmt1C = 70; # light-throttle onset
  tmt2C = 80; # heavy-throttle ceiling
in
{
  systemd.services.nvme-throttle = {
    description = "Lower NVMe HCTM self-throttle thresholds (cooler drives)";
    wantedBy = [ "multi-user.target" ];
    after = [ "local-fs.target" ];

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = pkgs.writeShellScript "nvme-throttle" ''
        set -u
        # NVMe thermal-management temps are in Kelvin; dword11 = (TMT1 << 16) | TMT2.
        t1=$(( ${toString tmt1C} + 273 ))
        t2=$(( ${toString tmt2C} + 273 ))
        val=$(( (t1 << 16) | t2 ))
        for d in /dev/nvme[0-9]; do
          [ -e "$d" ] || continue
          hctma=$(${pkgs.nvme-cli}/bin/nvme id-ctrl "$d" 2>/dev/null \
            | ${pkgs.gawk}/bin/awk -F: '/^hctma/{gsub(/[^x0-9a-f]/,"",$2);print $2}')
          if [ "''${hctma:-0x0}" != "0x1" ]; then
            echo "$d: HCTM unsupported, skipping"
            continue
          fi
          if ${pkgs.nvme-cli}/bin/nvme set-feature "$d" --feature-id=0x10 --value="$val" >/dev/null 2>&1; then
            echo "$d: self-throttle set to ${toString tmt1C}C/${toString tmt2C}C"
          else
            echo "$d: set-feature failed" >&2
          fi
        done
      '';
    };
  };

  # Keep the nvme CLI on the box for manual SMART/thermal checks (./nvme-check.sh etc.).
  environment.systemPackages = [ pkgs.nvme-cli ];
}
