# Samba on crimson

crimson shares `/vault` over SMB to the LAN
(`192.168.2.*`) and Tailscale. The share is read/write and requires a login —
no guest access. Config lives in `samba.nix`; mDNS (`crimson.local`) comes from
`../common/avahi.nix`.

## One-time server setup

After `just nix-rebuild` activates the module, set the Samba password (Samba
keeps its own password DB, separate from the Unix login):

```sh
sudo smbpasswd -a cullback
```

## Connect from macOS

1. Finder -> **Cmd-K** (Go -> Connect to Server).
2. Enter `smb://crimson.local` (or `smb://192.168.2.31` if mDNS is flaky).
3. Log in as `cullback` with the password set via `smbpasswd` above.

The share mounts under `/Volumes/vault`.

### Optional: stop macOS writing .DS_Store on network shares

Not required — the share already vetoes `.DS_Store` server-side — but this stops
the Mac even attempting it, on every network share:

```sh
defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true
killall Finder
```

## Apple metadata handling

- `._*` AppleDouble files are redirected into ZFS xattrs by the
  `fruit` / `streams_xattr` VFS settings, so they never hit disk as sidecars.
- `.DS_Store` and other Finder junk are blocked via `veto files`;
  `delete veto files` lets Samba clear dirs that hold only vetoed entries.
