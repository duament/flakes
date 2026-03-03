{ ... }:
{
  # Used to find the project root
  projectRootFile = "flake.nix";

  settings.excludes = [
    "pkgs/_sources/*"
    "secrets/*"
    "*/secrets.yaml"
  ];

  programs.keep-sorted.enable = true;

  programs.nixfmt.enable = true;

  programs.yamlfmt.enable = true;

  programs.stylua = {
    enable = true;
    settings = {
      indent_type = "Spaces";
      indent_width = 2;
      quote_style = "AutoPreferSingle";
      call_parentheses = "None";
    };
  };
}
