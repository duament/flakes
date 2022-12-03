{ config, lib, pkgs, ... }:
with lib;
let
  fcitx5-pinyin-zhwiki =
    let
      src = pkgs.fetchurl {
        url = "https://github.com/felixonmars/fcitx5-pinyin-zhwiki/releases/download/0.2.4/zhwiki-20221029.dict";
        sha256 = "sha256-GWbYTudS74iaw+7+mvcjt+QXkC4tFm+v4dDXWTx7aG8=";
      };
    in
    pkgs.runCommand "fcitx5-pinyin-zhwiki"
      {
        pname = "fcitx5-pinyin-zhwiki";
      } ''
      install -Dm644 ${src} $out/share/fcitx5/pinyin/dictionaries/zhwiki.dict
    '';
in
{
  options = {
    presets.workstation.enable = mkOption {
      type = types.bool;
      default = false;
    };
  };

  config = mkIf config.presets.workstation.enable {
    presets.ssh-agent.enable = true;
    presets.chromium.enable = true;

    hardware.enableRedistributableFirmware = true;
    hardware.logitech.wireless.enable = true;
    hardware.logitech.wireless.enableGraphical = true;

    boot.loader.grub.enable = false;

    networking.networkmanager.enable = true;
    networking.firewall.checkReversePath = "loose";

    services.xserver.enable = true;
    services.xserver.displayManager.gdm.enable = true;
    services.xserver.desktopManager.gnome.enable = true;

    xdg.portal.enable = true;

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
      fonts = with pkgs; mkForce [ inter source-serif hack-font noto-fonts-cjk-sans noto-fonts-cjk-serif noto-fonts-emoji ];
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
      fcitx5.addons = with pkgs; [
        fcitx5-chinese-addons
        fcitx5-pinyin-zhwiki
      ];
    };
  };
}
