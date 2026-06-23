{ config, pkgs, ... }:

# Mullvad WireGuard tunnel confined to a "vpn" network namespace. Anything run in
# that namespace (qBittorrent) can ONLY reach the network through the tunnel — if
# wg0 is down, the namespace has no route out, so it's a kill-switch by construction.
# kraken's own key/address (device "Busy Cow"), distinct from atlantix so both can
# run in parallel. To switch exit servers, change peer/endpoint below and rebuild.
let
  vpnNamespace = "vpn";
in
{
  sops.secrets.wg_privkey_kraken = { };

  boot.kernelModules = [ "wireguard" ];

  systemd.services.vpn-namespace = {
    description = "VPN Network Namespace";
    before = [ "wg-vpn.service" ];
    wantedBy = [ "multi-user.target" ];

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = pkgs.writeShellScript "vpn-ns-up" ''
        ${pkgs.iproute2}/bin/ip netns add ${vpnNamespace} || true
        ${pkgs.iproute2}/bin/ip netns exec ${vpnNamespace} ${pkgs.iproute2}/bin/ip link set lo up
      '';
      ExecStop = pkgs.writeShellScript "vpn-ns-down" ''
        ${pkgs.iproute2}/bin/ip netns delete ${vpnNamespace} || true
      '';
    };
  };

  systemd.services.wg-vpn = {
    description = "WireGuard VPN in namespace";
    after = [
      "vpn-namespace.service"
      "network-online.target"
    ];
    wants = [ "network-online.target" ];
    requires = [ "vpn-namespace.service" ];
    wantedBy = [ "multi-user.target" ];
    unitConfig.ConditionPathExists = config.sops.secrets.wg_privkey_kraken.path;

    path = [
      pkgs.wireguard-tools
      pkgs.iproute2
    ];

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = pkgs.writeShellScript "wg-up" ''
        ip link add wg0 type wireguard

        # NOTE: kraken's network blocks the default WireGuard UDP port (51820), so we
        # use port 53 — Mullvad accepts WireGuard on it and restrictive networks allow
        # it. (Verified: 51820 -> no handshake; 53 -> handshake OK.) Same applies if you
        # switch servers: keep an allowed port (53/123/4000-33433/…).
        wg set wg0 \
          private-key ${config.sops.secrets.wg_privkey_kraken.path} \
          peer "HjcUGVDXWdrRkaKNpc/8494RM5eICO6DPyrhCtTv9Ws=" \
          endpoint "178.249.214.2:53" \
          allowed-ips "0.0.0.0/0,::/0" \
          persistent-keepalive 25

        ip link set wg0 netns ${vpnNamespace}

        ip netns exec ${vpnNamespace} ip addr add 10.72.157.174/32 dev wg0
        ip netns exec ${vpnNamespace} ip link set wg0 up
        ip netns exec ${vpnNamespace} ip route add default dev wg0

        mkdir -p /etc/netns/${vpnNamespace}
        echo "nameserver 10.64.0.1" > /etc/netns/${vpnNamespace}/resolv.conf
      '';
      ExecStop = pkgs.writeShellScript "wg-down" ''
        ip netns exec ${vpnNamespace} ip link delete wg0 || true
        rm -rf /etc/netns/${vpnNamespace} || true
      '';
    };
  };

  environment.systemPackages = [
    pkgs.wireguard-tools # `wg` for debugging (e.g. `sudo vpn-exec wg show`)
    (pkgs.writeShellScriptBin "vpn-exec" ''
      exec ${pkgs.iproute2}/bin/ip netns exec ${vpnNamespace} "$@"
    '')
  ];
}
