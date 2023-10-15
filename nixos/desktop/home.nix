{ lib, pkgs, self, ... }: {
  imports = [
    self.nixosModules.myHomeModules
  ];

  presets.workstation.enable = true;
  wayland.windowManager.hyprland.settings.monitor = [
    "DP-1, preferred, auto, 2"
  ];

  presets.cert.enable = lib.mkForce false;

  home.packages = with pkgs; [
  ];
}
