# Minimal hardware configuration
# Hardware detection is handled by nixos-facter (facter.json)
# Disk configuration is handled by disko (disko.nix)
{ lib, ... }:

{
  # Platform is set by facter, but we keep this as a fallback
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
