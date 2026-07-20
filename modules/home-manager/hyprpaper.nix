{ ... }:
{
  flake.homeManagerModules.lkh-hyprpaper =
    { config, pkgs, ... }:
    let
      # Default wallpaper, now colocated in-repo (slugified name). The runtime
      # wallpaper picker overrides this live via hyprpaper IPC.
      selected_wallpaper_path = "${../../wallpapers/wood-dark.png}";
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
