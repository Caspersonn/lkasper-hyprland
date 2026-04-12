{ ... }:
{
  flake.homeManagerModules.lkh-ghostty =
    { config, pkgs, ... }:
    let
      cfg = config."lkasper-hyprland";
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

          gtk-single-instance = true;
          keybind = [ "ctrl+k=reset" ];
          confirm-close-surface = false;
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
