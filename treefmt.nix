{ ... }:
{
  # Used to find the project root
  projectRootFile = "flake.nix";

  programs.nixfmt.enable = true;
  settings.formatter.nixfmt.excludes = [ "pkgs/_sources/generated.nix" ];
}
