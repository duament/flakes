{ config, lib, ... }:
let
  cfg = config.presets.helix;
in
{
  options.presets.helix = {

    enable = lib.mkEnableOption "helix";

  };

  config = lib.mkIf cfg.enable {

    programs.helix = {
      enable = true;
      defaultEditor = false;
      settings = {
        theme = "catppuccin_latte";
        editor = {
          line-number = "relative";
          cursorline = true;
          color-modes = true;
          cursor-shape = {
            insert = "bar";
            normal = "block";
            select = "underline";
          };
          indent-guides.render = true;
        };
      };
    };

  };
}
