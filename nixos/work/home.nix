{ config, pkgs, self, ... }:
{
  imports = [
    self.nixosModules.myHomeModules
  ];

  presets.ssh.enable = true;
  presets.git.enable = true;
  presets.python.enable = true;

  home.packages = with pkgs; [
    checksec
    gcc
    gdb
    unar
    wireguard-tools
  ];

  programs.gpg.enable = true;
  programs.gpg.homedir = "${config.xdg.dataHome}/gnupg";
}
