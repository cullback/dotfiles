# Shared development environment for the interactive dev hosts (devy).
# Server/headless hosts deliberately do not import it.
{ pkgs, nixpkgs-unstable, ... }:

let
  unstable = import nixpkgs-unstable {
    system = pkgs.stdenv.hostPlatform.system;
    config.allowUnfree = true;
  };
in
{
  environment.systemPackages = with pkgs; [
    # Utilities
    moreutils
    wget

    # Data Tools
    qsv
    sqlite
    visidata

    # Development Tools
    perf
    tokei
    watchexec

    # Web & Browser
    chromium
    single-file-cli

    # Python
    (python313.withPackages (ps: [ ps.requests ]))
    pyright
    ruff

    # AI Assistants
    unstable.claude-code
  ];

  fonts.packages = with pkgs; [
    fira-code
  ];
}
