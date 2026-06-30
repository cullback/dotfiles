{
  imports = [
    ./hardware-configuration.nix
    ./services.nix
    ./time-sync.nix
    ./tailscale.nix
    ../common/dev.nix
    ../common/sops.nix
    ../common/syncthing.nix
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernel.sysctl."kernel.perf_event_paranoid" = 1;

  networking.hostName = "devy";
  networking.firewall.enable = false;

  security.sudo.wheelNeedsPassword = false;

  services.openssh.enable = true;
  programs.ssh.startAgent = true;

  services.syncthing.settings.folders = {
    "notes" = {
      path = "/home/cullback/repos/notes";
      devices = [
        "atlantix"
        "iphone14"
        "crimson"
        "kraken"
      ];
    };
  };

  system.autoUpgrade = {
    enable = true;
    dates = "weekly";
    allowReboot = false;
  };

  system.stateVersion = "25.05";
}
