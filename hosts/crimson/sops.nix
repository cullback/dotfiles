{ ... }:

# crimson's own sops scope. Its host-only secrets (wg key, Namecheap DDNS password)
# live in crimson.yaml, encrypted solely to crimson's SSH host key — so they can be
# created and decrypted on crimson alone. crimson replaces kraken as the server; see
# secrets/.sops.yaml for the per-host creation rules.
{
  sops.defaultSopsFile = ../secrets/crimson.yaml;
  sops.age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
}
