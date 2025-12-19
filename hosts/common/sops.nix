{ config, ... }:
{
  sops.defaultSopsFile = ../secrets/secrets.yaml;
  sops.age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];

  sops.secrets.openrouter_api_key = {
    owner = "cullback";
    group = "users";
  };

  programs.bash.interactiveShellInit = ''
    export OPENROUTER_API_KEY="$(cat ${config.sops.secrets.openrouter_api_key.path})"
  '';

  programs.fish.interactiveShellInit = ''
    set -gx OPENROUTER_API_KEY (cat ${config.sops.secrets.openrouter_api_key.path})
  '';
}
