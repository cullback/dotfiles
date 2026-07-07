{
  description = "NixOS configurations";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-26.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";
    # voxtype: push-to-talk voice-to-text. The flake's `onnx` package unlocks the
    # Cohere Transcribe / Parakeet engines (nixpkgs ships a Whisper-only build).
    # Keeps its own nixos-unstable pin so the ONNX/onnxruntime build matches upstream.
    voxtype.url = "github:peteonrails/voxtype";
    # Helium browser (privacy-focused Chromium fork) — not in nixpkgs. This flake
    # repackages imputnet's official .deb releases (same pattern as Brave/Vivaldi).
    helium-browser.url = "github:oxcl/nix-flake-helium-browser";
    helium-browser.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    {
      self,
      nixpkgs,
      nixpkgs-unstable,
      sops-nix,
      voxtype,
      helium-browser,
    }:
    let
      mkSystem =
        hostname: system:
        let
          # One shared unstable package set per host, passed to modules as `unstable`.
          unstable = import nixpkgs-unstable {
            inherit system;
            config.allowUnfree = true;
          };
        in
        nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = {
            inherit
              unstable
              voxtype
              helium-browser
              ;
          };
          modules = [
            sops-nix.nixosModules.sops
            ./${hostname}/configuration.nix
            ./common/users.nix
            ./common/packages.nix
            ./common/programs.nix
            ./common/nix-settings.nix
            ./common/locale.nix
            ./common/dbus.nix
          ];
        };
    in
    {
      nixosConfigurations = {
        crimson = mkSystem "crimson" "x86_64-linux";
      };
    };
}
