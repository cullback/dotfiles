{ ... }:

# kraken's own sops scope. Its host-only secrets (wg key, Namecheap DDNS password)
# live in kraken.yaml, encrypted solely to kraken's SSH host key — so they can be
# created and decrypted on kraken alone, and aren't exposed to devy/atlantix. The
# shared secrets.yaml (openrouter) belongs to those other hosts via common/sops.nix.
{
  sops.defaultSopsFile = ../secrets/kraken.yaml;
  sops.age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
}
