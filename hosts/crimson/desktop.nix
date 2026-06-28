{ pkgs, ... }:

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

  # Terminal (matches the macOS setup) + fonts with glyph coverage.
  environment.systemPackages = [ pkgs.ghostty ];

  fonts = {
    packages = with pkgs; [
      nerd-fonts.jetbrains-mono
      noto-fonts
      noto-fonts-emoji
    ];
    fontconfig.defaultFonts.monospace = [
      "JetBrainsMono Nerd Font"
      "Noto Sans Mono"
    ];
  };
}
