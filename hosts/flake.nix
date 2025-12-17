{
  description = "NixOS configurations";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";
    nixos-facter-modules.url = "github:nix-community/nixos-facter-modules";
  };

  outputs =
    {
      self,
      nixpkgs,
      nixpkgs-unstable,
      disko,
      nixos-facter-modules,
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
