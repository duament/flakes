{ pkgs, self, ... }: {
  imports = [
    self.nixosModules.myHomeModules
  ];

  home.packages = with pkgs; [
    ncdu
    wireguard-tools
  ];
}
