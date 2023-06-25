{ pkgs, self, ... }: {
  imports = [
    self.nixosModules.myHomeModules
  ];

  presets.workstation.enable = true;
  xdg.configFile."hypr/hyprland.conf".text = ''
    monitor = eDP-1, preferred, auto, 2
  '';

  home.packages = with pkgs; [
    acpi
    brightnessctl
  ];
}
