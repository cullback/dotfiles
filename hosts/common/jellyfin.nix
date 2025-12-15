{ ... }:
{
  services.jellyfin = {
    enable = true;
    user = "cullback";
    group = "users";
    dataDir = "/home/cullback/vault/state/jellyfin";
    openFirewall = true;
  };
}
