{ pkgs, self, ... }: {
  imports = [
    self.nixosModules.myHomeModules
  ];

  presets.workstation.enable = true;
  xdg.configFile."hypr/hyprland.conf".text = ''
    monitor = eDP-1, preferred, 320x1080, 2
    monitor = , preferred, 0x0, 2
  '';

  home.packages = with pkgs; [
    acpi
    brightnessctl
  ];
}
