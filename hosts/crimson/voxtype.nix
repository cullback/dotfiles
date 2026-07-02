{
  pkgs,
  voxtype,
  ...
}:

# voxtype: push-to-talk voice-to-text. The flake's `onnx` build provides the
# Cohere Transcribe / Parakeet engines (nixpkgs is Whisper-only). The hotkey is
# read via evdev (needs the "input" group); text injection falls back
# wtype -> dotool -> ydotool, with dotool the working path on GNOME Wayland
# (Mutter doesn't implement wtype's virtual-keyboard protocol).
#
# This module also owns the input-injection plumbing (ydotool + group
# membership).
{
  environment.systemPackages = [
    voxtype.packages.${pkgs.stdenv.hostPlatform.system}.onnx
    pkgs.dotool
  ];

  # ydotool: uinput-based input injection that works on GNOME Wayland. Sets up
  # the ydotoold user service, uinput access, and YDOTOOL_SOCKET.
  programs.ydotool.enable = true;

  # evdev hotkey needs "input"; "uinput" owns /dev/uinput (hardware.uinput,
  # enabled by kanata.nix; used by dotool/ydotool); "ydotool" reaches the
  # ydotoold socket (/run/ydotoold/socket, perm 0660 group ydotool).
  users.users.cullback.extraGroups = [
    "input"
    "uinput"
    "ydotool"
  ];
}
