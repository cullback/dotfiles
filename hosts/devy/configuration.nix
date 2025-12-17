{
  pkgs,
  nixpkgs-unstable,
  ...
}:

let
  unstable = import nixpkgs-unstable {
    system = pkgs.stdenv.hostPlatform.system;
    config.allowUnfree = true;
  };
in
{
  imports = [
    ./hardware-configuration.nix
    ./services.nix
    ./tailscale.nix
    ../common/syncthing.nix
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "devy";
  networking.firewall.enable = false;

  security.sudo.wheelNeedsPassword = false;

  services.openssh.enable = true;

  services.syncthing.settings.folders = {
    "notes" = {
      path = "/home/cullback/repos/notes";
      devices = [ "atlantix" ];
    };
  };

  environment.systemPackages = with pkgs; [
    moreutils
    wget

    # neat tools
    qsv
    visidata
    sqlite
    tokei
    watchexec
    single-file-cli
    chromium

    # python
    python313
    pyright
    ruff

    unstable.claude-code
    unstable.opencode
  ];

  system.autoUpgrade = {
    enable = true;
    dates = "weekly";
    allowReboot = false;
  };

  system.stateVersion = "25.05";
}
