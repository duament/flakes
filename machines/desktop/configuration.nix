{ config, pkgs, ... }:

{
  imports = [
    ../../modules/common.nix
  ];

  # boot.loader.systemd-boot.enable = true;
  # boot.loader.efi.canTouchEfiVariables = true;
  boot.initrd.luks.devices.cryptroot.allowDiscards = true;
  boot.loader.grub.enable = false;

  networking.hostName = "desktop";
  # networking.wireless.enable = true;
  networking.networkmanager.enable = true;

  services.xserver.enable = true;
  services.xserver.displayManager.gdm.enable = true;
  services.xserver.desktopManager.gnome.enable = true;

  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    #alsa.enable = true;
    #alsa.support32Bit = true;
    pulse.enable = true;
    #jack.enable = true;
  };

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    users.rvfg = import ./home.nix;
  };

  environment.systemPackages = with pkgs; [
    clash
  ];

  system.stateVersion = "22.11";
}

