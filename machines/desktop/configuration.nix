{ config, pkgs, ... }:
{
  # boot.loader.systemd-boot.enable = true;
  # boot.loader.efi.canTouchEfiVariables = true;
  boot.initrd.luks.devices.cryptroot.allowDiscards = true;

  networking.hostName = "desktop";
  # networking.wireless.enable = true;

  home-manager.users.rvfg = import ./home.nix;

  environment.systemPackages = with pkgs; [
    clash
  ];
}
