# Theming (tinty)

One colorscheme, applied across **Helix**, **Ghostty**, **Zellij** and **gitui**
with live reload. Powered by [tinty](https://github.com/tinted-theming/tinty)
and the base16/base24 systems (430+ schemes).

> base24 support: `tinted-helix` only commits base16 renders, so `install.fish`
> runs `tinty build` on the cloned template to generate its base24 themes. The
> hook maps base24's dedicated bright colors (base10-17) onto Ghostty's bright
> ANSI slots; base16 schemes reuse their normal colors there.

## How it works

```
scheme (e.g. base16-catppuccin-frappe)
        │  tinty apply <scheme>
        ▼
  apply.fish  (hook, gets the palette as $TINTY_SCHEME_PALETTE_BASE*_HEX_*)
  ├─ helix    copy tinted-helix render → ~/.config/helix/themes/tinty.toml → pkill -USR1 hx
  ├─ ghostty  generate              → ~/.config/ghostty/themes/tinty       → pkill -USR2 ghostty
  ├─ zellij   generate              → ~/.config/zellij/themes/tinty.kdl     → touch config.kdl (auto-reload)
  └─ gitui    generate              → ~/.config/gitui/theme.ron            → (applies on next launch)
```

Helix/Ghostty/Zellij configs statically point at a theme named `tinty`; only the
_file contents_ change on switch, so those configs never need editing. gitui has
no theme-name indirection — `theme.ron` _is_ the theme, so the hook generates it
directly (replacing the old repo symlink with a real file; `gitui/theme.ron` in
the repo is now just a static seed).

- `config.toml` — tinty config; the one `[[items]]` is Helix (official
  `tinted-helix` template). Symlinked to `~/.config/tinted-theming/tinty/`.
- `apply.fish` — the hook. Helix is rendered by tinty; Ghostty, Zellij and gitui
  have no official templates, so they're generated here from the same palette
  env vars. Symlinked to `~/.config/tinty/apply.fish`.

## Usage

```sh
just themes                                  # list schemes  (tinty list)
just theme base16-gruvbox-material-dark-medium   # switch all three
just theme-pick                              # interactive gallery
```

## Live reload, per tool

| Tool    | Mechanism                                                                                                                                                                                                                                 |
| ------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Zellij  | watches `config.kdl`; the hook `touch`es it to re-read the theme                                                                                                                                                                          |
| Helix   | `SIGUSR1` (`pkill -USR1 hx`) reloads config + theme, all windows                                                                                                                                                                          |
| Ghostty | `SIGUSR2` (`pkill -USR2 ghostty`) reloads config + theme — no focus or Accessibility permission needed (undocumented but present in the 1.3.1 binary: _"reloading configuration in response to SIGUSR2"_). Manual fallback: `cmd+shift+,` |
| gitui   | no live reload (no watch/signal); the regenerated `theme.ron` applies the next time gitui launches                                                                                                                                        |

**Terminal-default background:** gitui has no global-background option and the
bare shell area is the raw terminal surface, so both use Ghostty's `background`.
They only pick up a new background once Ghostty reloads (above). Helix is the
exception — its theme sets `ui.background`, so it repaints independently.

## Authoring / live-editing your own scheme

base16 schemes are small YAML palettes. To iterate on one with live feedback:

```sh
# edit a palette, then re-apply — the live tools reload in <1s
tinty apply ./my-scheme.yaml

# or auto-apply on every save (needs watchexec / entr):
watchexec -w my-scheme.yaml -- tinty apply my-scheme.yaml
```

A scheme YAML looks like:

```yaml
system: "base16"
name: "My Scheme"
variant: "dark"
palette:
  base00: "303446"  # bg
  base05: "c6d0f5"  # fg
  base08: "e78284"  # red
  # ... base01-04, 06-07, 09-0F
```

## Fresh machine

`fish hosts/macos/install.fish` (or `just sync-dotfiles`) symlinks the configs,
runs `tinty install` (clones templates), and applies a default scheme. Requires
`brew "tinty"` from the `tinted-theming/tinty` tap (in the Brewfile).
