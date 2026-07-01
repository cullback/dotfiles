# Syncthing on crimson. Shared device list + GUI come from common/syncthing.nix;
# here we declare crimson's folders, which live in the vault.
#
# crimson takes over the server role in the mesh (kraken + atlantix decommissioned):
#   admin  — passwords/docs, shared with phone + laptop
#   notes  — shared with phone
{ ... }:
{
  imports = [ ../common/syncthing.nix ];

  services.syncthing.settings.folders = {
    "admin" = {
      path = "/vault/admin";
      devices = [
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
      path = "/vault/repos/notes";
      devices = [
        "iphone14"
      ];
    };
  };
}
