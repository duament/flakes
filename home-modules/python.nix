{ config, lib, pkgs, ... }:
with lib;
let
  my-python-packages = python-packages: with python-packages; [
    python-lsp-server
    ipython
    requests
  ];
  python-with-my-packages = pkgs.python3.withPackages my-python-packages;
in {
  options = {
    presets.python.enable = mkOption {
      type = types.bool;
      default = false;
    };
  };

  config = mkIf config.presets.python.enable {
    home.packages = [ python-with-my-packages ];
  };
}
