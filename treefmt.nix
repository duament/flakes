{ ... }:
{
  # Used to find the project root
  projectRootFile = "flake.nix";

  settings.excludes = [
    "pkgs/_sources/*"
    "secrets/*"
    "*/secrets.yaml"
  ];

  programs.nixfmt.enable = true;

  programs.yamlfmt.enable = true;
}
