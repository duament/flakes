{ pkgs, self, ... }: {
  imports = [
    self.nixosModules.myHomeModules
  ];

  home.packages = with pkgs; [
    iperf
    pciutils
    usbutils
    wireguard-tools
  ];

  presets.git.enable = true;
}
