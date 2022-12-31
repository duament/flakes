{ pkgs, self, ... }: {
  imports = [
    self.nixosModules.myHomeModules
  ];

  home.packages = with pkgs; [
    iperf
    usbutils
    wireguard-tools
  ];

  presets.git.enable = true;
}
