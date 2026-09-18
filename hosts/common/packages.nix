{ pkgs, unstable, ... }:

let
  # ck ("seek"): semantic + grep code/prose search. Not in nixpkgs; built
  # from source, dynamically linked against the nixpkgs onnxruntime.
  ck-search = pkgs.callPackage ./ck.nix { };
in
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
    tokei # code statistics (lines of code by language)

    # Modern CLI Replacements
    bat
    ck-search # semantic + grep search (`ck`)
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
    # Tracks unstable: YouTube changes faster than the stable channel
    # updates. 26.05's 2026.07.04 took 403s on every adaptive stream,
    # leaving captures with metadata and no video; 2026.08.19 downloads
    # them again.
    unstable.yt-dlp

    # Build & Task Runners
    gdb # debugger
    just

    # Language Runtimes
    python3

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
