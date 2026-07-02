{ pkgs, helium-browser, ... }:

# Local Wayland desktop for crimson (monitor + keyboard). GNOME via GDM with
# autologin — a batteries-included base to start with; niri/sway can be added
# later as parallel sessions selectable at login.
{
  services.xserver.enable = true; # base X/xkb + XWayland for GNOME's Wayland session
  services.displayManager.gdm.enable = true;
  services.desktopManager.gnome.enable = true;
  # Keep the plain ssh-agent (programs.ssh.startAgent); disable GNOME's competing one.
  services.gnome.gcr-ssh-agent.enable = false;

  services.displayManager.autoLogin = {
    enable = true;
    user = "cullback";
  };

  # Browsers. Helium (privacy Chromium fork) comes from the helium-browser flake's
  # overlay, which exposes pkgs.helium; trying it out alongside Firefox.
  programs.firefox.enable = true;
  nixpkgs.overlays = [ helium-browser.overlays.default ];

  # Sound — PipeWire with pulse compat (pulled in by GNOME, but be explicit)
  services.pipewire = {
    enable = true;
    pulse.enable = true;
  };

  # OpenGL with 32-bit support — required for any Windows games (Wine/Proton)
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  # Terminal (matches the macOS setup) + desktop apps + fonts with glyph coverage.
  environment.systemPackages = with pkgs; [
    ghostty
    helium
    keepassxc

    # Gaming
    heroic # GOG / Epic launcher
    protonup-qt # runner manager (downloads GE-Proton/Wine-GE)
    mangohud # FPS overlay
    wineWow64Packages.wayland # Wine with Wayland support
    winetricks # helper for Wine components
  ];

  fonts = {
    packages = with pkgs; [
      nerd-fonts.fira-code
      noto-fonts
      noto-fonts-color-emoji
    ];
    fontconfig.defaultFonts.monospace = [
      "FiraCode Nerd Font"
      "Noto Sans Mono"
    ];
  };
}
