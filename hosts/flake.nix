{
  description = "NixOS configurations";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-26.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";
    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";
    nixos-facter-modules.url = "github:nix-community/nixos-facter-modules";
    # voxtype: push-to-talk voice-to-text. The flake's `onnx` package unlocks the
    # Cohere Transcribe / Parakeet engines (nixpkgs ships a Whisper-only build).
    # Keeps its own nixos-unstable pin so the ONNX/onnxruntime build matches upstream.
    voxtype.url = "github:peteonrails/voxtype";
  };

  outputs =
    {
      self,
      nixpkgs,
      nixpkgs-unstable,
      sops-nix,
      disko,
      nixos-facter-modules,
      voxtype,
    }:
    let
      mkSystem =
        hostname: system:
        nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = {
            inherit nixpkgs-unstable voxtype;
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
        devy = mkSystem "devy" "aarch64-linux";
        kraken = mkSystem "kraken" "x86_64-linux";
        crimson = mkSystem "crimson" "x86_64-linux";
        atlantix = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = {
            inherit nixpkgs-unstable;
          };
          modules = [
            sops-nix.nixosModules.sops
            disko.nixosModules.disko
            nixos-facter-modules.nixosModules.facter
            ./atlantix/disko.nix
            ./atlantix/configuration.nix
            ./common/users.nix
            ./common/packages.nix
            ./common/programs.nix
            ./common/nix-settings.nix
            ./common/locale.nix
            ./common/dbus.nix
          ];
        };
      };
    };
}
