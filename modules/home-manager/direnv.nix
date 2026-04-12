{ ... }:
{
  flake.homeManagerModules.lkh-direnv =
    { ... }:
    {
      programs.direnv = {
        enable = true;
        enableZshIntegration = true;
        nix-direnv.enable = true;
      };
    };
}
