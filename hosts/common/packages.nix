{ pkgs, ... }:

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
    pandoc
    yt-dlp

    # markdown
    marksman
    harper

    # formatters
    nixfmt-rfc-style
    dprint
    dprint-plugins.dprint-plugin-markdown
    dprint-plugins.dprint-plugin-toml
    dprint-plugins.dprint-plugin-json
  ];
}
