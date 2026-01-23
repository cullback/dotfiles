{ pkgs, nixpkgs-unstable, ... }:

let
  unstable = import nixpkgs-unstable {
    system = pkgs.stdenv.hostPlatform.system;
    config.allowUnfree = true;
  };
in
{
  nixpkgs.config.allowUnfree = true;
  environment.systemPackages = with pkgs; [
    # System
    age
    parted

    # Shell & Terminal
    fzf
    starship
    zellij

    # Editor & File Management
    helix
    yazi

    # Version Control
    delta
    git
    gitui

    # Modern CLI Replacements
    bat
    dust
    eza
    fd
    ripgrep
    sd

    # Data Processing
    jq
    pandoc
    yq-go

    # Media
    yt-dlp

    # Build & Task Runners
    just

    # Language Servers
    harper
    marksman

    # Formatters
    nixfmt-rfc-style
    unstable.dprint
    unstable.dprint-plugins.dprint-plugin-json
    unstable.dprint-plugins.dprint-plugin-markdown
    unstable.dprint-plugins.dprint-plugin-toml
  ];
}
