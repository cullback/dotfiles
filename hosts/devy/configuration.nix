{
  pkgs,
  nixpkgs-unstable,
  ...
}:

let
  unstable = import nixpkgs-unstable {
    system = pkgs.system;
    config.allowUnfree = true;
  };
in
{
  imports = [
    ./hardware-configuration.nix
    ./services.nix
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "devy";
  networking.firewall.enable = false;

  services.openssh.enable = true;

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

  system.stateVersion = "25.05";
}
