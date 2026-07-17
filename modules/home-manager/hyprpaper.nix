{ ... }:
{
  flake.homeManagerModules.lkh-hyprpaper =
    { config, pkgs, ... }:
    let
      selected_wallpaper_path = "~/lkasper-flake/wallpapers/Wood Dark.png";
    in
    {
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
