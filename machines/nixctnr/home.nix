{ config, pkgs, self, ... }:
{
  imports = [
    self.nixosModules.myHomeModules
  ];

  presets.ssh.enable = true;
  presets.git.enable = true;

  home.packages = with pkgs; [
    sops
    unar
  ];
}
