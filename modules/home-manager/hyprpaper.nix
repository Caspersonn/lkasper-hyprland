{ ... }:
{
  flake.homeManagerModules.lkh-hyprpaper =
    { lib, ... }:
    let
      pairs = import ../../wallpapers/pairs.nix;
      pairNames = builtins.attrNames pairs;
      defaultPair = if builtins.elem "beach" pairNames then "beach" else builtins.head pairNames;
      wallpapers = lib.concatMap (
        pair:
        map (mode: "${../../wallpapers + "/${pairs.${pair}.${mode}}"}") [
          "light"
          "dark"
        ]
      ) pairNames;
      defaultWallpaper = "${../../wallpapers + "/${pairs.${defaultPair}.dark}"}";
    in
    {
      services.hyprpaper = {
        enable = true;
        settings = {
          preload = wallpapers;
          wallpaper = [
            {
              monitor = "";
              path = defaultWallpaper;
              fit_mode = "cover";
            }
          ];
        };
      };
    };
}
