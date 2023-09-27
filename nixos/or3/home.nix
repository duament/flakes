{ pkgs, self, ... }: {
  imports = [
    self.nixosModules.myHomeModules
  ];

  home.packages = with pkgs; [
    wireguard-tools
  ];
}
