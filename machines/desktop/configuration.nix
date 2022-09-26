{ config, pkgs, ... }:
{
  # boot.loader.systemd-boot.enable = true;
  # boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "desktop";

  home-manager.users.rvfg = import ./home.nix;

  environment.systemPackages = with pkgs; [
    clash
  ];
}
