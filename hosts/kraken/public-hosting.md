# Public media hosting on kraken

kraken serves Jellyfin and Navidrome to the public internet over HTTPS, directly
from home — no VPS in the path. It replaced atlantix (a Hetzner VPS) as the public
front door.

| URL                         | Service               | Backend on kraken |
| --------------------------- | --------------------- | ----------------- |
| `https://movies.benburk.ca` | Jellyfin (films + TV) | `localhost:8096`  |
| `https://music.benburk.ca`  | Navidrome (music)     | `localhost:4533`  |

## Request flow

```
client ──DNS(Namecheap)──▶ 76.65.22.121 (home WAN, dynamic)
       ──▶ Bell Giga Hub 2.0  ──port-forward 443──▶ 192.168.2.11 (kraken)
       ──▶ Caddy (TLS, Let's Encrypt)  ──reverse_proxy──▶ Jellyfin / Navidrome
```

Only ports **80 and 443** are forwarded from the WAN. Everything else (SSH, Samba,
Syncthing, the Jellyfin/Navidrome ports themselves) is reachable on the LAN and
Tailscale only — never from the internet.

## Why this works on a Bell residential line

- **Connection:** Bell Giga Hub 2.0, GPON fibre. The WAN IP equals the public IP
  (verified: modem WAN `76.65.22.121` == `curl api.ipify.org`), so the line is
  **not behind CGNAT** — inbound port-forwarding works. (Bell is rolling CGNAT out
  to some customers in 2026; re-check if inbound ever stops working.)
- **Dynamic IP:** the public IPv4 can change. Today the Namecheap A records are
  **pinned manually** to `76.65.22.121`. See "Known gaps" — DDNS is not yet set up.

## Key facts / inventory

| Thing          | Value                                                     |
| -------------- | --------------------------------------------------------- |
| kraken LAN IP  | `192.168.2.11` (DHCP-reserved in the Giga Hub)            |
| kraken MAC     | `a8:b8:e0:09:d0:5d`                                       |
| Home WAN IP    | `76.65.22.121` (dynamic)                                  |
| Modem          | Bell Giga Hub 2.0 @ `192.168.2.1`                         |
| Port forwards  | TCP `80→80`, `443→443` → kraken                           |
| DNS            | Namecheap, `movies`/`music` A records → WAN IP, TTL 5 min |
| TLS            | Let's Encrypt via Caddy (`email cullback@fastmail.com`)   |
| kraken tailnet | `100.126.6.48` / `kraken.taile2df60.ts.net`               |
| Replaced       | atlantix (Hetzner `5.161.206.7`)                          |

## Config

- `../common/caddy.nix` — the reverse proxy and vhosts (`movies`/`music.benburk.ca`).
- `configuration.nix` — imports `../common/caddy.nix` and opens firewall `80`/`443`.

Deploy from kraken:

```bash
cd ~/repos/dotfiles
sudo nixos-rebuild switch --flake ./hosts#kraken   # or: just nix-rebuild
```

## Temporarily disabling public access

Jellyfin and Navidrome let the first visitor claim the admin account, so lock out
the public before running their first-time setup. Stop the reverse proxy:

```bash
sudo systemctl stop caddy     # both public URLs go dead immediately
sudo systemctl start caddy    # restore public HTTPS
```

While stopped, configure the apps over Tailscale (`http://kraken:8096`,
`http://kraken:4533`) or the LAN. This is imperative — a reboot restarts Caddy. To
disable across reboots, comment out the `../common/caddy.nix` import and rebuild.

## Verifying

```bash
# DNS resolves to the home WAN IP
nix shell nixpkgs#dnsutils -c dig +short @1.1.1.1 movies.benburk.ca

# HTTPS works with a valid cert (run from OUTSIDE the LAN, e.g. cellular / a VPS).
# ssl_verify_result=0 means the cert is trusted; 302 = app redirect to its web UI.
curl -s -o /dev/null -w "%{http_code} verify=%{ssl_verify_result}\n" https://movies.benburk.ca
```

## Troubleshooting

- **Can't reach kraken on the LAN:** its DHCP lease may have drifted. It is now
  reserved at `192.168.2.11`; confirm in the Giga Hub DHCP table. Prefer
  `ssh kraken` over Tailscale, which is immune to LAN-IP changes.
- **Public sites time out (HTTP 000) from outside:** check, in order — Caddy
  running (`systemctl status caddy`); kraken firewall allows 80/443
  (`configuration.nix`); the two modem port-forwards exist and are **saved**; the
  line hasn't been moved to CGNAT (modem WAN IP vs `curl api.ipify.org` — if they
  differ, you're behind CGNAT and need a relay/VPS again).
- **Cert won't issue:** Caddy needs DNS pointing at the WAN IP and port 80 reachable
  for the Let's Encrypt HTTP-01 challenge. Verify both, then
  `journalctl -u caddy`.

## Known gaps / TODO

- **No DDNS.** The A records are pinned to a static IP; if Bell changes the WAN IP,
  both sites break until updated. Add `services.ddclient` on kraken (protocol
  `namecheap`, hosts `movies`/`music`) with the Namecheap Dynamic-DNS password
  stored as an agenix secret.
- **atlantix decommission.** kraken has fully taken over; atlantix can be retired
  once you've confirmed nothing else depends on it. SSH fallback: `5.161.206.7`.
