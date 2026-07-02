{ config, pkgs, ... }:

{
  # Fully declarative accounts: no imperatively-set passwords that drift or block a
  # reproducible reinstall. cullback's login hash comes from sops (defined in the
  # host's sops scope with neededForUsers, so it's decrypted before user activation).
  users.mutableUsers = false;
  users.defaultUserShell = pkgs.fish;
  users.users.cullback = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    hashedPasswordFile = config.sops.secrets.cullback_pw.path;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGUvNZI9LHiN7RmqBxDt5wiawgec9BHAAkAtMidrf5/b cullback"
    ];
  };
}
