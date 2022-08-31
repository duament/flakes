{ lib, ... }:
{
  imports = [
    ./common.nix
  ];

  networking = {
    useDHCP = false;
    useNetworkd = true;
  };

  systemd.network.networks."80-ethernet" = {
    enable = true;
    matchConfig = { Type = "ether"; };
    DHCP = lib.mkDefault "yes";
  };

  fonts.fontconfig.enable = false;
  xdg = {
    autostart.enable = false;
    icons.enable = false;
    menus.enable = false;
    mime.enable = false;
    sounds.enable = false;
  };
}
