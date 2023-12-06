{ pkgs, self, ... }: {
  imports = [
    self.nixosModules.myHomeModules
  ];

  home.packages = with pkgs; [
    iperf
    pciutils
    usbutils
  ];

  presets.git.enable = true;
}
