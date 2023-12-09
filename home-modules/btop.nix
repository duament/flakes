{ config, lib, pkgs, ... }:
let
  cfg = config.presets.btop;
  catppuccin = pkgs.catppuccin.override {
    variant = "latte";
  };
in
{
  options = {
    presets.btop.enable = lib.mkEnableOption "";
  };

  config = lib.mkIf cfg.enable {

    programs.btop = {
      enable = true;
      settings = {
        color_theme = "catppuccin_latte";
        theme_background = false;
      };
    };

    xdg.configFile."btop/themes".source = "${catppuccin}/btop";
  };
}
