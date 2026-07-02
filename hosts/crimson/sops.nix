{ config, ... }:

# crimson's own sops scope. Its host-only secrets (wg key, Namecheap DDNS password,
# openrouter API key) live in crimson.yaml, encrypted solely to crimson's SSH host key
# — so they can be created and decrypted on crimson alone. crimson replaces kraken as
# the server; see secrets/.sops.yaml for the per-host creation rules.
{
  sops.defaultSopsFile = ../secrets/crimson.yaml;
  sops.age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];

  # openrouter API key (migrated from the decommissioned devy's shared secrets.yaml).
  sops.secrets.openrouter_api_key = {
    owner = "cullback";
    group = "users";
  };

  # cullback's login password hash (mkpasswd -m sha-512). neededForUsers makes
  # sops-nix decrypt it to /run/secrets-for-users before user activation, which is
  # required for users.users.<name>.hashedPasswordFile (see common/users.nix).
  sops.secrets.cullback_pw.neededForUsers = true;

  programs.bash.interactiveShellInit = ''
    export OPENROUTER_API_KEY="$(cat ${config.sops.secrets.openrouter_api_key.path})"
  '';

  programs.fish.interactiveShellInit = ''
    set -gx OPENROUTER_API_KEY (cat ${config.sops.secrets.openrouter_api_key.path})
  '';
}
