{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.presets.python;
  my-python-packages =
    python-packages:
    with python-packages;
    [
      python-lsp-server
      rope
      toml
      whatthepatch
      python-lsp-ruff

      ipython
      requests
    ]
    ++ cfg.extraPackages python-packages;
  python-with-my-packages = pkgs.python3.withPackages my-python-packages;
in
{
  options = {
    presets.python.enable = mkOption {
      type = types.bool;
      default = false;
    };

    presets.python.extraPackages = mkOption {
      type = types.functionTo (types.listOf types.package);
      default = _: [ ];
    };
  };

  config = mkIf config.presets.python.enable {

    home.packages = [ python-with-my-packages ];

    home.activation.ipython = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      mkdir -p ~/.local/share/ipython
      ln -sf .local/share/ipython ~/.ipython
    '';
  };

}
