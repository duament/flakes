{ pkgs, self, ... }:
{
  imports = [
    self.nixosModules.myHomeModules
  ];

  presets.workstation.enable = true;
  wayland.windowManager.hyprland.settings.monitor = [
    "DP-1, preferred, auto, 2"
  ];

  home.packages = with pkgs; [
    ethtool
  ];
}
