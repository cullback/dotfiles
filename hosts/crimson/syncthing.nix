# Syncthing on crimson. Shared device list + GUI come from common/syncthing.nix;
# here we declare crimson's folders, which live in the vault.
#
# crimson takes over kraken's role in the mesh (kraken decommissioned):
#   admin  — passwords/docs, shared with atlantix + phone + laptop
#   notes  — shared with atlantix + devy + phone
{ ... }:
{
  imports = [ ../common/syncthing.nix ];

  services.syncthing.settings.folders = {
    "admin" = {
      path = "/home/cullback/vault/admin";
      devices = [
        "atlantix"
        "iphone14"
        "macbook-air"
      ];
      # Safety net for the passwords folder: a deleted/overwritten file is
      # recoverable from .stversions for 30 days (guards a bad first reconcile).
      versioning = {
        type = "trashcan";
        params.cleanoutDays = "30";
      };
    };
    "notes" = {
      path = "/home/cullback/vault/repos/notes";
      devices = [
        "atlantix"
        "devy"
        "iphone14"
      ];
    };
  };
}
