{ pkgs, unstable, ... }:

{
  nixpkgs.config.allowUnfree = true;
  environment.systemPackages = with pkgs; [
    # System
    age
    parted
    sops
    ssh-to-age

    # Shell & Terminal
    direnv
    fzf
    moreutils # includes vipe (edit a pipe in $EDITOR)
    ghostty.terminfo
    starship
    zellij

    # Editor & File Management
    helix
    yazi

    # Version Control
    delta
    gh
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
    qsv # CSV toolkit
    visidata # terminal spreadsheet / tabular data explorer
    yq-go

    # Media
    yt-dlp

    # Build & Task Runners
    just

    # Language Servers
    # harper -- uses a lot of ram
    markdown-oxide

    # Formatters
    nixfmt
    unstable.dprint
    unstable.dprint-plugins.dprint-plugin-json
    unstable.dprint-plugins.dprint-plugin-markdown
    unstable.dprint-plugins.dprint-plugin-toml
  ];

  environment.variables = {
    DIRENV_LOG_FORMAT = "";
  };
}
