{ config, pkgs, ... }:

# Mullvad WireGuard tunnel confined to a "vpn" network namespace. Anything run in
# that namespace (qBittorrent) can ONLY reach the network through the tunnel — if
# wg0 is down, the namespace has no route out, so it's a kill-switch by construction.
# crimson's own key/address, distinct from kraken/atlantix so all can run in parallel.
# To switch exit servers, change peer/endpoint below and rebuild.
let
  vpnNamespace = "vpn";

  # crimson's Mullvad-assigned WireGuard address for the wg_privkey_crimson device
  # (Mullvad device "social turtle"). Retrieved from Mullvad's WireGuard API for the
  # device matching crimson's wg public key.
  crimsonWgAddress = "10.75.56.33/32";
in
{
  sops.secrets.wg_privkey_crimson = { };

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
    unitConfig.ConditionPathExists = config.sops.secrets.wg_privkey_crimson.path;

    path = [
      pkgs.wireguard-tools
      pkgs.iproute2
    ];

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = pkgs.writeShellScript "wg-up" ''
        ip link add wg0 type wireguard

        wg set wg0 \
          private-key ${config.sops.secrets.wg_privkey_crimson.path} \
          peer "HjcUGVDXWdrRkaKNpc/8494RM5eICO6DPyrhCtTv9Ws=" \
          endpoint "178.249.214.2:51820" \
          allowed-ips "0.0.0.0/0,::/0" \
          persistent-keepalive 25

        ip link set wg0 netns ${vpnNamespace}

        ip netns exec ${vpnNamespace} ip addr add ${crimsonWgAddress} dev wg0
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
