{ pkgs, self, ... }: {
  imports = [
    self.nixosModules.myHomeModules
  ];

  presets.workstation.enable = true;
  wayland.windowManager.hyprland.settings.monitor = [
    "eDP-1, preferred, 320x1080, 2"
    ", preferred, 0x0, 2"
  ];

  home.packages = with pkgs; [
    acpi
    brightnessctl
  ];
}
