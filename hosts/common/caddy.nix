{ ... }:

{
  services.caddy = {
    enable = true;
    email = "cullback@fastmail.com";

    virtualHosts = {
      "movies.benburk.ca" = {
        extraConfig = ''
          reverse_proxy localhost:8096
        '';
      };
    };
  };
}
