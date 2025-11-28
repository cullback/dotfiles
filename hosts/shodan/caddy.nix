{ ... }:

{
  services.caddy = {
    enable = true;
    email = "cullback@fastmail.com";

    virtualHosts = {
      "ai.benburk.ca".extraConfig = ''
        reverse_proxy localhost:8080
      '';
    };
  };
}
