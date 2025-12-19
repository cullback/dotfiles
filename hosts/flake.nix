{
  description = "NixOS configurations";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";
    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";
    nixos-facter-modules.url = "github:nix-community/nixos-facter-modules";
    agenix.url = "github:ryantm/agenix";
    agenix.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    {
      self,
      nixpkgs,
      nixpkgs-unstable,
      sops-nix,
      disko,
      nixos-facter-modules,
      agenix,
    }:
    let
      mkSystem =
        hostname: system:
        nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = {
            inherit nixpkgs-unstable;
          };
          modules = [
            sops-nix.nixosModules.sops
            ./${hostname}/configuration.nix
            ./common/users.nix
            ./common/packages.nix
            ./common/programs.nix
            ./common/nix-settings.nix
            ./common/locale.nix
          ];
        };
    in
    {
      nixosConfigurations = {
        devy = mkSystem "devy" "aarch64-linux";
        atlantix = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = {
            inherit nixpkgs-unstable;
          };
          modules = [
            agenix.nixosModules.default
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
          ];
        };
      };
    };
}
