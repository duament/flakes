{ config, lib, ... }:
with lib;
{
  options = {
    presets.nogui.enable = mkOption {
      type = types.bool;
      default = false;
    };
  };

  config = mkIf config.presets.nogui.enable {
    networking = {
      useDHCP = false;
      useNetworkd = true;
    };

    systemd.network.networks."80-ethernet" = {
      enable = true;
      matchConfig = { Type = "ether"; };
      DHCP = mkDefault "yes";
    };

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
