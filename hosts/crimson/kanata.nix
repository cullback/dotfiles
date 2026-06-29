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
          1    2    3    4    5    6    7    8    9    0    -    =
          q    w    e    r    t    y    u    i    o    p
          caps a    s    d    f    g    h    j    k    l    ;    '
          b    n    m    ,    .    /
          ret
        )

        (defalias
          cap (tap-hold-press 200 200 esc (layer-while-held nav))
          slw (macro C-left C-S-right)   ;; select word
          sll (macro home S-end)         ;; select line
          olb (macro end ret)            ;; open line below
        )

        ;; base = "bold" layout (physical key -> emitted key)
        (deflayer base
          1    2    3    4    5    6    7    8    9    0    -    =
          b    l    d    f    w    /    ,    o    y    k
          @cap r    n    s    t    m    u    a    e    i    h    '
          g    ;    .    q    j    p
          ret
        )

        ;; nav = caps held. _ = transparent (falls through to base/bold).
        ;; Hold Alt too -> the arrows below become Alt+arrows (zellij panes).
        (deflayer nav
          brdn brup _    _    _    _    prev pp   next mute vold volu
          _    _    _    _    _    _    _    _    _    _
          _    @slw @sll _    _    _    home left down up   right end
          _    _    _    _    _    _
          @olb
        )
      '';
    };
  };
}
