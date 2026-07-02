{ config, pkgs, ... }:
{
  services.syncthing = {
    enable = true;
    user = "cullback";
    dataDir = "/home/cullback/.local/share/syncthing";
    configDir = "/home/cullback/.config/syncthing";

    # GUI is loopback-only; tailscale serve fronts it with HTTPS on the tailnet
    # (see common/tailscale.nix — the cert, not app auth, blocks DNS rebinding).
    guiAddress = "127.0.0.1:8384";

    overrideDevices = true;
    overrideFolders = true;

    settings = {
      devices = {
        iphone14 = {
          id = "P7D6TDJ-EM4PIG6-W3AHLYZ-VVSQVME-7AOS5E3-7FPAPCM-52GAQZO-XAVKCQ7";
        };
        macbook-air = {
          id = "O2QNTQH-2XGCZ6N-7TP7QXA-E22L6IG-J3EPPTQ-R7LMVSX-KKSPSSI-FKSHJAB";
        };
        crimson = {
          id = "DZAECZQ-DXCQMV7-IF7LPCM-E3DOTB3-6OQGF5B-KY2O765-SUIP2TY-55COWQ7";
        };
      };
      gui = {
        # No login: with the GUI reachable only via loopback + tailscale serve,
        # TLS carries the rebinding defense and the tailnet is trusted. The
        # explicit empty user matters — a GUI password was set at one point, and
        # since syncthing-init PATCHes only the keys listed here, omitting user
        # would leave that login enabled forever. user="" alone disables static
        # auth (syncthing requires user AND password); the old hash lingering in
        # config.xml is inert — syncthing won't store an empty password field, so
        # it can't be scrubbed via the API, only ignored.
        user = "";
        # serve forwards the browser's Host (the ts.net name), which fails
        # syncthing's localhost-bind host check; safe to skip behind the cert.
        insecureSkipHostcheck = true;
      };
    };
  };

  networking.firewall.allowedTCPPorts = [ 22000 ];
  networking.firewall.allowedUDPPorts = [
    22000
    21027
  ];
}
