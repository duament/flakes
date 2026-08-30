{
  config,
  lib,
  pkgs,
  self,
  ...
}:
let
  inherit (lib)
    # keep-sorted start
    concatMapStrings
    concatStrings
    elem
    filterAttrs
    mapAttrsToList
    mkDefault
    mkForce
    mkIf
    mkOption
    types
    # keep-sorted end
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

    nixpkgs.overlays = [
      (self: super: {
        kdePackages = super.kdePackages.overrideScope (
          kdeSelf: kdeSuper: {
            kwin = kdeSuper.kwin.overrideAttrs (oldAttrs: {
              patches = (oldAttrs.patches or [ ]) ++ [
                (super.fetchpatch2 {
                  url = "https://invent.kde.org/plasma/kwin/-/commit/2d0613ac.patch";
                  hash = "sha256-e4CAL/ZgtO2xeJExhb+sZ9B17gQPtGqTWvPkdt9uXVg=";
                })
              ];
            });
          }
        );
      })
    ];

    sops.secrets = {
      wireless.sopsFile = ../secrets/wireless.yaml;
      d-auth = {
        sopsFile = ../secrets/workstation.yaml;
        owner = "rvfg";
      };
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

    console.font = "${pkgs.spleen}/share/consolefonts/spleen-16x32.psfu";

    i18n.inputMethod = {
      enable = true;
      type = "fcitx5";
      fcitx5 = {
        addons = with pkgs; [
          qt6Packages.fcitx5-chinese-addons
          fcitx5-pinyin-zhwiki
          fcitx5-pinyin-moegirl
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

    networking.wireless = {
      enable = mkDefault true;
      userControlled = true;
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

    networking.nftables.allowContainerVeth = true;

    environment.systemPackages = with pkgs; [
      # keep-sorted start
      android-tools
      dmidecode
      e2fsprogs
      efibootmgr
      ifuse
      libimobiledevice
      libplist
      sbsigntool
      smartmontools
      strongswan
      # keep-sorted end
    ];

    preservation.preserveAt."/persist".users.rvfg = {
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
              # keep-sorted start
              "Noto Music"
              "Noto Sans Bamum"
              "Noto Sans Javanese"
              "Noto Sans Math"
              "Noto Sans Oriya"
              "Noto Sans Symbols 2"
              "Noto Sans Symbols"
              "Noto Sans Thai"
              "Noto Serif Tibetan"
              # keep-sorted end
            ];
          })
        ];
      fontconfig = {
        defaultFonts = {
          monospace = [
            "Hack"
            "Symbols Nerd Font"
            "Noto Sans Mono CJK SC"
          ];
          sansSerif = [
            "Inter Variable"
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

            <selectfont>
              <rejectfont>
                <pattern>
                  <patelt name="family">
                    <string>DejaVu Sans</string>
                  </patelt>
                </pattern>
              </rejectfont>
            </selectfont>

            ${concatStrings (
              mapAttrsToList
                (font: genericfamily: ''
                  <match target="scan">
                    <test name="family">
                      <string>${font}</string>
                    </test>
                    <edit name="genericfamily" mode="assign_replace">
                      <const>${genericfamily}</const>
                    </edit>
                  </match>
                '')
                {
                  # keep-sorted start
                  "Aleo" = "serif";
                  "Hack" = "monospace";
                  "Inter Variable" = "sans-serif";
                  "Inter" = "sans-serif";
                  # keep-sorted end
                }
            )}

            ${concatStrings (
              mapAttrsToList
                (font: prefer: ''
                  <alias binding="same">
                    <family>${font}</family>
                    <prefer>
                      <family>${prefer}</family>
                    </prefer>
                  </alias>
                '')
                {
                  # keep-sorted start
                  "-apple-system" = "sans-serif";
                  "Arial" = "sans-serif";
                  "Helvetica" = "sans-serif";
                  "Noto Sans" = "sans-serif";
                  "system-ui" = "sans-serif";
                  # keep-sorted end
                  "Source Code Pro" = "Hack";
                }
            )}

          </fontconfig>
        '';
      };
    };

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

    programs.wireshark = {
      enable = true;
      package = pkgs.wireshark;
    };

    services.usbmuxd.enable = true;

    users.users.rvfg.extraGroups = [
      # keep-sorted start
      "adbusers"
      "wireshark"
      "wpa_supplicant"
      # keep-sorted end
    ];

    nixpkgs.config.allowUnfreePredicate =
      pkg:
      builtins.elem (lib.getName pkg) [
        "fcitx5-pinyin-moegirl"
      ];

  };
}
