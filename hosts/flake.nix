{
  description = "NixOS configurations";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
  };

  outputs =
    {
      self,
      nixpkgs,
      nixpkgs-unstable,
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
        shodan = mkSystem "shodan" "x86_64-linux";
      };
    };
}
