{ config, lib, pkgs, self, ... }:
let
  inherit (lib) mkOption mkIf mkForce types;
  directMark = 1;
in
{
  options = {
    presets.workstation.enable = mkOption {
      type = types.bool;
      default = false;
    };
  };

  config = mkIf config.presets.workstation.enable {

    nixpkgs.overlays = [
      (self: super: {
        wpa_supplicant = super.wpa_supplicant.overrideAttrs (oldAttrs: {
          extraConfig = oldAttrs.extraConfig + ''
            CONFIG_SUITEB=y
            CONFIG_SUITEB192=y
          '';
        });
      })
    ];

    sops.secrets = {
      clash = {
        format = "binary";
        sopsFile = ../secrets/clash;
      };
      wireless.sopsFile = ../secrets/wireless.yaml;
    };

    boot = {
      loader.grub.enable = false;
      kernel.sysctl."kernel.sysrq" = 1;
      extraModulePackages = [ config.boot.kernelPackages.v4l2loopback ];
      kernelModules = [ "v4l2loopback" ];
    };

    presets.refind = {
      enable = true;
      sign = true;
      extraConfig = ''
        banner icons/bg_black.png
        small_icon_size 144
        big_icon_size 384
        selection_big   icons/selection_black-big.png
        selection_small icons/selection_black-small.png
        font hack-28.24.png
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
      enable = false;
      route = "cn";
    };

    services.clash = {
      enable = true;
      configFile = config.sops.secrets.clash.path;
    };

    networking.wireless = {
      enable = true;
      userControlled = {
        enable = true;
        group = "rvfg";
      };
      environmentFile = config.sops.secrets."wireless".path;
      networks = {
        "Xiaomi_3304_5G".psk = "@PSK_3304@";
        a5.psk = "@PSK_a5@";
        eduroam = {
          authProtocols = [ "WPA-EAP" "WPA-EAP-SUITE-B-192" "FT-EAP" "FT-EAP-SHA384" ];
          auth = ''
            eap=PEAP
            identity="@EDUROAM_ID@"
            password="@EDUROAM_PWD@"
          '';
        };
      };
    };
    systemd.network.networks."99-wireless-client-dhcp" = {
      linkConfig.RequiredForOnline = true;
      routingPolicyRules = [
        {
          routingPolicyRuleConfig = {
            Family = "both";
            FirewallMark = directMark;
            Priority = 9;
          };
        }
      ];
      # domains = [ "~h.rvf6.com" ];
    };

    networking.firewall = {
      checkReversePath = "loose";
      allowedTCPPortRanges = [{ from = 1714; to = 1764; }]; # KDE Connect
      allowedUDPPortRanges = [{ from = 1714; to = 1764; }]; # KDE Connect
    };

    environment.systemPackages = with pkgs; [
      ifuse
      libimobiledevice
      libplist
      pcscliteWithPolkit.out # Workaround #280826
      strongswan
    ];

    environment.persistence."/persist".users.rvfg = {
      directories = [
        ".config/chromium"
        ".config/kdeconnect"
        ".config/fcitx5"
        ".gnupg"
        ".mozilla"
        ".thunderbird"
        "Downloads"
      ];
    };

    environment.pathsToLink = [ "/share/fcitx5/themes" ];

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
      enableDefaultPackages = false;
      packages = with pkgs; mkForce [
        inter
        source-serif
        hack-font
        noto-fonts-cjk-sans
        noto-fonts-cjk-serif
        noto-fonts-color-emoji
        aleo
        (nerdfonts.override { fonts = [ "NerdFontsSymbolsOnly" ]; })
        (noto-fonts.override { variants = [ "Noto Music" "Noto Sans Symbols" "Noto Sans Symbols 2" "Noto Sans Math" ]; })
      ];
      fontconfig = {
        defaultFonts = {
          monospace = [ "Hack" "Symbols Nerd Font" ];
          sansSerif = [ "Inter" "Noto Sans CJK SC" ];
          serif = [ "Aleo" "Noto Serif CJK SC" ];
        };
        hinting.enable = false;
        subpixel.lcdfilter = "none";
        subpixel.rgba = "none";
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

    programs.hyprland = {
      enable = true;
      package = pkgs.hyprland.overrideAttrs (old: {
        patches = old.patches ++ [
          ./0001-Add-cgroup2-in-windowrulev2.patch
        ];
      });
    };
    hardware.opengl.enable = true;
    security.pam.services.swaylock = { };
    services.greetd = {
      enable = true;
      settings =
        let
          hyprland-script = pkgs.writeShellScript "start-hyprland" ''
            systemctl --user import-environment PATH SSH_AUTH_SOCK NIX_USER_PROFILE_DIR NIX_PROFILES XDG_SEAT XDG_SESSION_CLASS XDG_SESSION_ID
            exec systemctl --wait --user start hyprland.service
          '';
        in
        {
          initial_session = {
            user = "rvfg";
            command = hyprland-script;
          };
          default_session = {
            command = "${pkgs.greetd.tuigreet}/bin/tuigreet --cmd ${hyprland-script}";
          };
        };
    };

    qt = {
      enable = true;
      platformTheme = "qt5ct";
    };

    services.udisks2.enable = true;

    services.syncthing = {
      enable = true;
      openDefaultPorts = true;
      cert = config.sops.secrets."syncthing/cert".path;
      key = config.sops.secrets."syncthing/key".path;
      settings = {
        devices = self.data.syncthing.devices;
        folders = lib.getAttrs [ "keepass" "notes" "session" ] self.data.syncthing.folders;
      };
    };
    systemd.tmpfiles.rules = [ "d ${config.services.syncthing.dataDir} 2770 syncthing syncthing -" "a ${config.services.syncthing.dataDir} - - - - d:g::rwx" ];

    programs.adb.enable = true;

    programs.wireshark = {
      enable = true;
      package = pkgs.wireshark;
    };

    services.usbmuxd.enable = true;

    users.users.rvfg.extraGroups = [ "syncthing" "adbusers" "wireshark" ];

  };
}
