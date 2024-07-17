{ config, lib, pkgs, ... }:
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
    #presets.hyprland.enable = true;
    presets.cert.enable = true;

    home.packages = with pkgs; [
      imagemagick
      imv
      inetutils
      inkscape
      iputils
      keepassxc
      libreoffice-fresh
      openssl
      papirus-icon-theme
      pciutils
      pdftk
      poppler_utils
      tdesktop
      thunderbird
      unar
      usbutils
      wineWow64Packages.unstableFull
      wl-clipboard
      yubikey-manager
    ];

    systemd.user.tmpfiles.rules = [
      "L %h/syncthing - - - - /var/lib/syncthing"
    ];

    #i18n.inputMethod = {
    #  enabled = "fcitx5";
    #  fcitx5.addons = with pkgs; [
    #    fcitx5-chinese-addons
    #    fcitx5-pinyin-zhwiki
    #    fcitx5-theme
    #  ];
    #};
    #home.sessionVariables.GTK_IM_MODULE = lib.mkForce "wayland";
    #home.sessionVariables.QT_IM_MODULE = lib.mkForce "";
    #systemd.user.services.fcitx5-daemon.Service = {
    #  Type = "dbus";
    #  BusName = "org.fcitx.Fcitx-0";
    #};

    home.sessionVariables = {
      KDE_APPLICATIONS_AS_SERVICE = "1";
      GTK_USE_PORTAL = "1";
    };

    home.file.".local/share/konsole/Catppuccin-Latte.colorscheme".text = builtins.readFile ./Catppuccin-Latte.colorscheme;

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
        stretch-image-subs-to-screen = true;
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
      scripts = with pkgs.mpvScripts; [
        thumbfast
        uosc
      ];
      scriptOpts.uosc.languages = [ "en" ];
    };

    programs.zathura.enable = true;

    services.etesync-dav = {
      enable = true;
      serverUrl = "https://ete.rvf6.com/";
      package = pkgs.etesync-dav.override { python3 = pkgs.python311; };
    };

    services.kdeconnect = {
      enable = true;
      indicator = true;
    };

    programs.alacritty = {
      enable = true;
      settings = {
        import = [ "${pkgs.alacritty-theme}/catppuccin_latte.toml" ];
        scrolling.history = 10000;
      };
    };

  };
}
