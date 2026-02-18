{ ... }:
{
  flake.homeManagerModules.omarchy-direnv =
    { ... }:
    {
      programs.direnv = {
        enable = true;
        enableZshIntegration = true;
        nix-direnv.enable = true;
      };
    };
}
