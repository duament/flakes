{ config, pkgs, ... }:
{
  presets.workstation.enable = true;

  sops.defaultSopsFile = ./secrets.yaml;
  sops.secrets."sbsign-key" = {};
  sops.secrets."sbsign-cert" = {};
  sops.secrets."clash" = {
    format = "binary";
    sopsFile = ../../lib/clash.secrets;
  };

  boot.loader = {
    efi.efiSysMountPoint = "/efi";
    refind = {
      enable = true;
      sign = true;
      signKey = config.sops.secrets."sbsign-key".path;
      signCert = config.sops.secrets."sbsign-cert".path;
      extraConfig = ''
        banner icons/bg_black.png
        small_icon_size 144
        big_icon_size 384
        selection_big   icons/selection_black-big.png
        selection_small icons/selection_black-small.png
        font hack-48.18.png
        showtools firmware, shell, gdisk, memtest
        scanfor external,optical,manual
        use_graphics_for osx,linux,windows

        menuentry "Arch Linux" {
            loader /EFI/Arch/linux-signed.efi
            submenuentry "Boot using linux-signed.efi.bak" {
                loader /EFI/Arch/linux-signed.efi.bak
            }
            submenuentry "Boot linux-dracut" {
                loader /EFI/Arch/linux-dracut.efi
            }
            submenuentry "Boot archiso" {
                loader /EFI/Arch/archiso-signed.efi
            }
        }

        menuentry "Windows 10" {
            loader /EFI/Microsoft/Boot/bootmgfw.efi
        }
      '';
    };
  };

  networking.hostName = "desktop";

  home-manager.users.rvfg = import ./home.nix;

  services.clash.enable = true;
  services.clash.configFile = config.sops.secrets.clash.path;
}
