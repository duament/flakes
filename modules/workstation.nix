{ config, lib, mypkgs, pkgs, self, ... }:
with lib;
{
  options = {
    presets.workstation.enable = mkOption {
      type = types.bool;
      default = false;
    };
  };

  config = mkIf config.presets.workstation.enable {
    boot.loader.grub.enable = false;
    boot.kernel.sysctl."kernel.sysrq" = 1;
    presets.refind = {
      enable = true;
      defaultSelection = "Arch Linux";
      sign = true;
      extraConfig = ''
        banner icons/bg_black.png
        small_icon_size 144
        big_icon_size 384
        selection_big   icons/selection_black-big.png
        selection_small icons/selection_black-small.png
        font hack-48.18.png
        showtools firmware, shell, gdisk, memtest
        scanfor external,optical,manual

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
            graphics on
        }

        menuentry "Windows" {
            loader /EFI/Microsoft/Boot/bootmgfw.efi
            graphics on
        }
      '';
    };

    presets.wireguard.wg0 = {
      enable = true;
      route = "cn";
    };
    networking.firewall.checkReversePath = "loose";

    presets.ssh-agent.enable = true;
    presets.chromium.enable = true;

    hardware.enableRedistributableFirmware = true;
    hardware.bluetooth.enable = true;
    hardware.logitech.wireless.enable = true;
    hardware.logitech.wireless.enableGraphical = true;

    xdg.portal.enable = true;

    security.polkit.enable = true;

    security.rtkit.enable = true;
    hardware.pulseaudio.enable = false;
    services.pipewire = {
      enable = true;
      #alsa.enable = true;
      #alsa.support32Bit = true;
      pulse.enable = true;
      #jack.enable = true;
    };

    services.pcscd.enable = true;
    programs.gnupg.agent.enable = true;

    fonts = {
      enableDefaultFonts = false;
      fonts = with pkgs; mkForce [
        inter
        source-serif
        hack-font
        noto-fonts-cjk-sans
        noto-fonts-cjk-serif
        noto-fonts-emoji
        (nerdfonts.override { fonts = [ "NerdFontsSymbolsOnly" ]; })
      ];
      fontconfig = {
        defaultFonts = {
          monospace = [ "Hack" ];
          sansSerif = [ "Inter" "Noto Sans CJK SC" ];
          serif = [ "Source Serif" "Noto Serif CJK SC" ];
        };
        subpixel.lcdfilter = "none";
        localConf = ''
          <?xml version="1.0"?>
          <!DOCTYPE fontconfig SYSTEM "urn:fontconfig:fonts.dtd">
          <fontconfig>

            <alias>
              <family>Source Code Pro</family>
              <prefer>
                <family>Hack</family>
              </prefer>
            </alias>

          </fontconfig>
        '';
      };
    };

    i18n.inputMethod = {
      enabled = "fcitx5";
      fcitx5.addons = with pkgs; with mypkgs; [
        fcitx5-chinese-addons
        fcitx5-pinyin-zhwiki
      ];
    };
  };
}
