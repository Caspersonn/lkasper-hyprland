{ ... }:
{
  flake.homeManagerModules.lkh-hyprpaper =
    { config, pkgs, ... }:
    let
      selected_wallpaper_path = "~/Pictures/Wallpapers/gruvbox/3-cosy-retreat-sunset.png";
    in
    {
      home.file = {
        "Pictures/Wallpapers" = {
          source = ../../config/themes/wallpapers;
          recursive = true;
        };
      };
      services.hyprpaper = {
        enable = true;
        settings = {
          preload = [ selected_wallpaper_path ];
          wallpaper = [
            {
              monitor = "";
              path = selected_wallpaper_path;
              fit_mode = "cover";
            }
          ];
        };
      };
    };
}
