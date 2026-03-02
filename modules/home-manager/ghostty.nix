{ ... }:
{
  flake.homeManagerModules.omarchy-ghostty =
    { config, pkgs, ... }:
    let
      cfg = config.omarchy;
    in
    {
      programs.ghostty = {
        enable = true;
        settings = {
          window-padding-x = 14;
          window-padding-y = 14;
          background-opacity = 0.95;
          window-decoration = "none";

          font-family = cfg.primary_font;
          font-size = 12;

          config-file = "~/.config/omarchy/current/theme/ghostty.conf";
          gtk-single-instance = true;
          keybind = [ "ctrl+k=reset" ];
        };
      };

      #home.file.".local/share/applications/com.mitchellh.ghostty.desktop".text =
      #  ''
      #    [Desktop Entry]
      #    Name=Ghostty
      #    GenericName=Terminal Emulator
      #    Comment=Fast, native, feature-rich terminal emulator
      #    Exec=ghostty %U
      #    Type=Application
      #    Icon=com.mitchellh.ghostty
      #    Categories=System;TerminalEmulator;
      #    Terminal=false
      #    StartupNotify=true
      #  '';
    };
}
