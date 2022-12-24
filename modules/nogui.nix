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

    presets.nogui.enableNetwork = mkOption {
      type = types.bool;
      default = true;
    };
  };

  config = mkIf cfg.enable {
    networking = {
      useDHCP = false;
      useNetworkd = true;
    };

    systemd.network.networks = mkIf cfg.enableNetwork {
      "80-ethernet" = {
        enable = true;
        matchConfig = { Type = "ether"; };
        DHCP = mkDefault "yes";
      };
    };

    environment.noXlibs = true;
    xdg = {
      autostart.enable = false;
      icons.enable = false;
      menus.enable = false;
      mime.enable = false;
      sounds.enable = false;
    };
  };
}
