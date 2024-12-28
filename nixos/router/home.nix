{ pkgs, self, ... }:
{
  imports = [
    self.nixosModules.myHomeModules
  ];

  home.packages = with pkgs; [
    ethtool
    iperf
    lm_sensors
    pciutils
    powertop
    usbutils
  ];

  presets.git.enable = true;
}
