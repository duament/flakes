{ config, lib, ... }:
with lib;
let
  cfg = config.presets.nogui;
in
{
  options = {
    presets.nogui.enable = mkOption {
      type = types.bool;
      default = false;
    };
  };

  config = mkIf cfg.enable {
    fonts.fontconfig.enable = false;
    xdg = {
      autostart.enable = false;
      icons.enable = false;
      menus.enable = false;
      mime.enable = false;
      sounds.enable = false;
    };
  };
}
