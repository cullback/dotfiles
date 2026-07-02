{ ... }:

# Keyboard remapping (kanata) — ports the macOS Karabiner setup to Linux:
#   - "bold" custom alpha layout (karabiner/bold_layout.json)
#   - caps lock: tap = Esc, hold = nav layer (karabiner/capslock.json)
#
# Zellij pane focus: caps + Alt + j/k/l/;  ->  Alt+arrows. No special binding
# needed — a held Alt passes through and combines with the nav-layer arrows.
# (Avoid the Super/"win" key for this — it's owned by the desktop.)
#
# Notes on the port:
#   - Mac-only keys (mission_control, launchpad, keyboard illumination) have no
#     Linux equivalent and are left transparent (fall through to the base layer).
#   - Editing motions are translated to Linux conventions (Ctrl+arrow = word,
#     Home/End = line). The stateful multi-tap "extend selection" is simplified to
#     a single select-word / select-line for now.
{
  hardware.uinput.enable = true;

  services.kanata = {
    enable = true;
    keyboards.monsgeek = {
      devices = [ "/dev/input/by-id/usb-_MonsGeek_Keyboard-event-kbd" ];
      extraDefCfg = "process-unmapped-keys yes";
      config = ''
        (defsrc
          esc  1    2    3    4    5    6    7    8    9    0    -    =    bspc
          q    w    e    r    t    y    u    i    o    p
          caps a    s    d    f    g    h    j    k    l    ;    '
          b    n    m    ,    .    /
          ret
        )

        (defalias
          cap (tap-hold-press 200 200 esc (layer-while-held nav))
          cpq (tap-hold-press 200 200 esc (layer-while-held navq))
          slw (macro C-left C-S-right)   ;; select word
          sll (macro home S-end)         ;; select line
          olb (macro end ret)            ;; open line below
          qwe (layer-switch qwerty)      ;; switch base to qwerty
          bld (layer-switch base)        ;; switch base back to bold
        )

        ;; base = "bold" layout (physical key -> emitted key)
        (deflayer base
          grv  1    2    3    4    5    6    7    8    9    0    -    =    bspc
          b    l    d    f    w    /    ,    o    y    k
          @cap r    n    s    t    m    u    a    e    i    h    '
          g    ;    .    q    j    p
          ret
        )

        ;; nav = caps held. _ = transparent (falls through to base/bold).
        ;; Hold Alt too -> the arrows below become Alt+arrows (zellij panes).
        ;; caps+1 switches the base layout to qwerty (reclaimed brdn slot).
        (deflayer nav
          _    @qwe brup _    _    _    _    prev pp   next mute vold volu del
          _    _    _    _    _    _    _    _    _    _
          _    @slw @sll _    _    _    home left down up   right end
          _    _    _    _    _    _
          @olb
        )

        ;; qwerty base layer. Activated by layer-switch, so _ = the defsrc key,
        ;; i.e. plain qwerty. Only caps is remapped, to reach navq.
        (deflayer qwerty
          _    _    _    _    _    _    _    _    _    _    _    _    _    _
          _    _    _    _    _    _    _    _    _    _
          @cpq _    _    _    _    _    _    _    _    _    _    _
          _    _    _    _    _    _
          _
        )

        ;; nav while qwerty is the base — same as nav, but caps+1 switches back
        ;; to bold. slw/sll/arrows etc. work the same here.
        (deflayer navq
          _    @bld brup _    _    _    _    prev pp   next mute vold volu del
          _    _    _    _    _    _    _    _    _    _
          _    @slw @sll _    _    _    home left down up   right end
          _    _    _    _    _    _
          @olb
        )
      '';
    };
  };
}
