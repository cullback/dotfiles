{ ... }:

{
  services.caddy = {
    enable = true;
    email = "cullback@fastmail.com";

    virtualHosts = {
      "sync.benburk.ca".extraConfig = ''
        reverse_proxy localhost:8384
      '';

      "ai.benburk.ca".extraConfig = ''
        reverse_proxy localhost:8080
      '';
    };
  };
}
