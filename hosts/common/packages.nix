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
    # system
    parted
    age

    # core tools
    fzf
    git
    gitui
    helix
    just
    yazi
    zellij
    starship

    # replacements
    bat
    dust
    eza
    fd
    ripgrep
    sd
    delta
    jq
    yq
    pandoc
    yt-dlp

    # markdown
    marksman
    harper

    # formatters
    nixfmt-rfc-style
    unstable.dprint
    unstable.dprint-plugins.dprint-plugin-markdown
    unstable.dprint-plugins.dprint-plugin-toml
    unstable.dprint-plugins.dprint-plugin-json
  ];
}
