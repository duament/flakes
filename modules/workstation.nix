{
  config,
  lib,
  pkgs,
  self,
  ...
}:
let
  inherit (lib)
    mkOption
    mkIf
    mkDefault
    mkForce
    types
    filterAttrs
    elem
    ;
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
      kernelPatches = [
        {
          name = "logitech";
          patch = ./logitech.patch;
        }
      ];
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

    i18n.inputMethod = {
      enable = true;
      type = "fcitx5";
      fcitx5 = {
        addons = with pkgs; [
          qt6Packages.fcitx5-chinese-addons
          fcitx5-pinyin-zhwiki
          fcitx5-theme
        ];
        waylandFrontend = true;
      };
    };

    services.tailscale = {
      enable = true;
      openFirewall = true;
      extraUpFlags = [
        "--accept-dns=false"
        "--netfilter-mode=off"
      ];
    };
    presets.bpf-mark.tailscaled = 1;

    services.clash = {
      enable = true;
      configFile = config.sops.secrets.clash.path;
    };

    networking.wireless = {
      enable = mkDefault true;
      userControlled = {
        enable = true;
        group = "rvfg";
      };
      secretsFile = config.sops.secrets."wireless".path;
      networks = {
        a5.psk = "ext:PSK_a5";
      };
    };
    systemd.network.networks."99-wireless-client-dhcp" = {
      linkConfig.RequiredForOnline = true;
      routingPolicyRules = [
        {
          Family = "both";
          FirewallMark = directMark;
          Priority = 64;
        }
      ];
      # domains = [ "~h.rvf6.com" ];
    };

    networking.firewall = {
      checkReversePath = "loose";
      allowedTCPPortRanges = [
        {
          from = 1714;
          to = 1764;
        }
      ]; # KDE Connect
      allowedUDPPortRanges = [
        {
          from = 1714;
          to = 1764;
        }
      ]; # KDE Connect
    };

    environment.systemPackages = with pkgs; [
      dmidecode
      e2fsprogs
      efibootmgr
      ifuse
      libimobiledevice
      libplist
      sbsigntool
      smartmontools
      strongswan
    ];

    environment.persistence."/persist".users.rvfg = {
      directories = [
        ".config"
        ".gnupg"
        ".mozilla"
        ".thunderbird"
        "Downloads"
        "Desktop"
        "Documents"
        "Music"
        "Pictures"
        "Public"
        "Templates"
        "Videos"
      ];
    };

    environment.pathsToLink = [ "/share/fcitx5/themes" ];

    presets.chromium.enable = true;

    hardware.enableRedistributableFirmware = true;
    hardware.bluetooth.enable = true;
    hardware.logitech.wireless.enable = true;
    hardware.logitech.wireless.enableGraphical = true;

    xdg.portal = {
      enable = true;
      extraPortals = with pkgs; [ xdg-desktop-portal-gtk ];
    };

    security.polkit.enable = true;

    security.rtkit.enable = true;
    services.pulseaudio.enable = false;
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
      packages =
        with pkgs;
        mkForce [
          inter
          source-serif
          hack-font
          noto-fonts-cjk-sans
          noto-fonts-cjk-serif
          noto-fonts-color-emoji
          aleo
          nerd-fonts.symbols-only
          (noto-fonts.override {
            variants = [
              "Noto Music"
              "Noto Sans Symbols"
              "Noto Sans Symbols 2"
              "Noto Sans Math"
              "Noto Sans Thai"
              "Noto Sans Oriya"
            ];
          })
        ];
      fontconfig = {
        defaultFonts = {
          monospace = [
            "Hack"
            "Symbols Nerd Font"
          ];
          sansSerif = [
            "Inter"
            "Noto Sans CJK SC"
          ];
          serif = [
            "Aleo"
            "Noto Serif CJK SC"
          ];
        };
        hinting.enable = true;
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

    #programs.hyprland = {
    #  enable = true;
    #  package = pkgs.hyprland.overrideAttrs (old: {
    #    patches = old.patches ++ [
    #      ./0001-Add-cgroup2-in-windowrulev2.patch
    #    ];
    #  });
    #};
    #hardware.opengl.enable = true;
    #security.pam.services.swaylock = { };
    #services.greetd = {
    #  enable = true;
    #  settings =
    #    let
    #      hyprland-script = pkgs.writeShellScript "start-hyprland" ''
    #        systemctl --user import-environment PATH SSH_AUTH_SOCK NIX_USER_PROFILE_DIR NIX_PROFILES XDG_SEAT XDG_SESSION_CLASS XDG_SESSION_ID
    #        exec systemctl --wait --user start hyprland.service
    #      '';
    #    in
    #    {
    #      initial_session = {
    #        user = "rvfg";
    #        command = hyprland-script;
    #      };
    #      default_session = {
    #        command = "${pkgs.greetd.tuigreet}/bin/tuigreet --cmd ${hyprland-script}";
    #      };
    #    };
    #};

    #qt = {
    #  enable = true;
    #  platformTheme = "qt5ct";
    #};

    services.desktopManager.plasma6.enable = true;
    services.displayManager.sddm = {
      enable = true;
      wayland.enable = true;
    };

    services.udisks2.enable = true;

    services.syncthing = {
      enable = true;
      openDefaultPorts = true;
      cert = config.sops.secrets."syncthing/cert".path;
      key = config.sops.secrets."syncthing/key".path;
      user = "rvfg";
      group = "rvfg";
      settings = {
        devices = self.data.syncthing.devices;
        folders = filterAttrs (_: v: elem config.networking.hostName v.devices) self.data.syncthing.folders;
      };
    };
    systemd.services.syncthing = {
      environment.HOME = "/var/lib/syncthing";
      serviceConfig.ProtectHome = true;
    };

    programs.adb.enable = true;

    programs.wireshark = {
      enable = true;
      package = pkgs.wireshark;
    };

    services.usbmuxd.enable = true;

    users.users.rvfg.extraGroups = [
      "adbusers"
      "wireshark"
    ];

  };
}
