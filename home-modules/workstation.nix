{ config, lib, mypkgs, pkgs, ... }:
{
  options = {
    presets.workstation.enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
  };

  config = lib.mkIf config.presets.workstation.enable {
    presets.ssh.enable = true;
    presets.browser.enable = true;
    presets.python.enable = true;
    presets.hyprland.enable = true;
    presets.cert.enable = true;

    home.packages = with pkgs; [
      imv
      inetutils
      keepassxc
      openssl
      tdesktop
      thunderbird
      unar
      usbutils
      wireguard-tools
      yubikey-manager
    ];

    systemd.user.tmpfiles.rules = [
      "L %h/syncthing - - - - /var/lib/syncthing"
    ];

    i18n.inputMethod = {
      enabled = "fcitx5";
      fcitx5.addons = with pkgs; with mypkgs; [
        fcitx5-chinese-addons
        fcitx5-pinyin-zhwiki
      ];
    };
    systemd.user.services.fcitx5-daemon.Service = {
      Type = "dbus";
      BusName = "org.fcitx.Fcitx-0";
    };
    xdg.configFile."fcitx5/config".text = lib.generators.toINI { } {
      Hotkey = {
        EnumerateWithTriggerKeys = "True";
      };
      "Hotkey/TriggerKeys"."0" = "Super+space";
      "Behavior/DisabledAddons"."0" = "cloudpinyin";
    };
    home.activation.copyFcitx5Profile =
      let
        fcitx5Profile = lib.generators.toINI { } {
          "Groups/0" = {
            Name = "Default";
            "Default Layout" = "us";
            DefaultIM = "shuangpin";
          };
          "Groups/0/Items/0".Name = "keyboard-us";
          "Groups/0/Items/1".Name = "shuangpin";
          GroupOrder."0" = "Default";
        };
        fcitx5ProfileFile = pkgs.writeText "fcitx5-profile" fcitx5Profile;
      in
      lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        $DRY_RUN_CMD install -Dm644 ${fcitx5ProfileFile} ${config.xdg.configHome}/fcitx5/profile
      '';
    xdg.configFile."fcitx5/conf/classicui.conf".text = lib.generators.toKeyValue { } {
      PerScreenDPI = "True";
      WheelForPaging = "True";
      Font = "Sans Serif 12";
      MenuFont = "Sans 12";
      TrayFont = "Sans Bold 12";
      TrayOutlineColor = "#000000";
      TrayTextColor = "#ffffff";
      PreferTextIcon = "False";
      ShowLayoutNameInIcon = "True";
      UseInputMethodLangaugeToDisplayText = "True";
      Theme = "default";
    };
    xdg.configFile."fcitx5/conf/clipboard.conf".text = lib.generators.toINIWithGlobalSection { } {
      globalSection."Number of entries" = 10;
      sections.TriggerKey."0" = "Super+V";
    };

    presets.git.enable = true;
    programs.git.extraConfig.gcrypt = {
      participants = "F2E3DA8DE23F4EA11033EDEC535D184864C05736";
      publish-participants = true;
    };

    programs.gpg = {
      enable = true;
      scdaemonSettings.disable-ccid = true;
    };

    programs.mpv = {
      enable = true;
      config = rec {
        fullscreen = true;
        ao = "pipewire";
        vo = "gpu-next";
        hwdec = "vaapi";
        gpu-api = "vulkan";
        gpu-context = "waylandvk";
        # profile = "gpu-hq";
        slang-append = [ "zh-Hans" "zh-CN" "zh" "chi" "zh-Hant" "zh-TW" "zh-HK" "en-US" "en-GB" "en" ];
        audio-file-auto = "fuzzy";
        sub-auto = "fuzzy";
        sub-font-size = 36;
        sub-border-size = 0;
        sub-shadow-color = "#000000";
        sub-shadow-offset = 1;
        video-align-y = -1;
        sub-ass-force-margins = true;
        audio-display = false;
        ytdl-raw-options-append = [
          "format=bestvideo[height<=1440][fps>=60]+bestaudio/bestvideo[height<=1440]+bestaudio/best[height<=1440]/best"
          "write-sub="
          "sub-lang=${builtins.concatStringsSep "," slang-append}"
        ];
        # gpu-hq with workaround for cscale
        scale = "spline36";
        cscale = "bilinear";
        dscale = "mitchell";
        dither-depth = "auto";
        correct-downscaling = true;
        linear-downscaling = true;
        sigmoid-upscaling = true;
        deband = true;
        # uosc
        osc = false;
        osd-bar = false;
      };
      scripts = with pkgs.mpvScripts; [ thumbfast uosc ];
    };

    programs.zathura.enable = true;

    services.etesync-dav = {
      enable = true;
      serverUrl = "https://ete.rvf6.com/";
    };

    services.kdeconnect = {
      enable = true;
      indicator = true;
    };

    services.fusuma = {
      enable = true;
      settings = {
        interval.swipe = 0.8;
        swipe."3" = {
          left.command = "${pkgs.wtype}/bin/wtype -P XF86Forward -p XF86Forward";
          right.command = "${pkgs.wtype}/bin/wtype -P XF86Back -p XF86Back";
        };
      };
    };
  };
}
