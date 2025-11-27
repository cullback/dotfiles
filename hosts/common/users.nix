{ pkgs, ... }:

{
  users.defaultUserShell = pkgs.fish;
  users.users.cullback = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGUvNZI9LHiN7RmqBxDt5wiawgec9BHAAkAtMidrf5/b cullback@fastmail.com"
    ];
  };
}
