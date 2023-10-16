{ config, lib, pkgs, self, ... }:
let
  cfg = config.presets.hyprland;
  publicBinds = [
    "/nix"
    "/run/opengl-driver"
    "/run/current-system"
    "-%h/.config/fontconfig"
    "-%h/.config/qt5ct"
    "-%h/.config/qt6ct"
    "-%h/.config/Kvantum"
    "-%h/.config/fcitx5"
    "-%h/.local/share/fcitx5"
  ];
in
{
  config = lib.mkIf cfg.enable {
    systemd.user.tmpfiles.rules = [
      "d %h/.cache/keepassxc - - - -"
      "d %h/.local/share/keepassxc - - - -"
      "d %h/.mozilla/native-messaging-hosts - - - -"
    ] ++ [
      "d %h/.local/share/TelegramDesktop - - - -"
      ''d "%h/Downloads/Telegram\x20Desktop" - - - -''
    ];

    systemd.user.services.keepassxc-w4 = {
      Unit.After = [ "graphical-session.target" ];
      Install.WantedBy = [ "graphical-session.target" ];
      Service = self.data.systemdHarden // {
        Type = "dbus";
        BusName = "org.keepassxc.KeePassXC.MainWindow";
        BindPaths = [ "%t" "%h/.local/share/keepassxc:%h/.config/keepassxc" "%h/.cache/keepassxc" "-/var/lib/syncthing" "-%h/.mozilla/native-messaging-hosts" "-%h/.config/chromium/NativeMessagingHosts" ];
        BindReadOnlyPaths = publicBinds;
        ExecStart = "${pkgs.keepassxc}/bin/keepassxc";
        ProtectHome = "tmpfs";
        DynamicUser = false;
        PrivateDevices = false;
        PrivateNetwork = false;
        PrivateIPC = false;
        RestrictAddressFamilies = [ "AF_UNIX" "AF_INET" "AF_INET6" "AF_NETLINK" ];
        DeviceAllow = "/dev/dri";
        DevicePolicy = "closed";
        Environment = [ "QT_IM_MODULE=fcitx" ];
      };
    };

    systemd.user.services.telegram-w5 = {
      Unit.After = [ "graphical-session.target" ];
      Install.WantedBy = [ "graphical-session.target" ];
      Service = self.data.systemdHarden // {
        Type = "dbus";
        BusName = "org.telegram";
        MemoryHigh = "2G";
        BindPaths = [ "%t" "%h/.local/share/TelegramDesktop" "%h/Downloads/Telegram\\ Desktop" ];
        BindReadOnlyPaths = publicBinds;
        ExecStart = "${pkgs.telegram-desktop}/bin/telegram-desktop";
        ProtectHome = "tmpfs";
        DynamicUser = false;
        PrivateDevices = false;
        PrivateNetwork = false;
        PrivateIPC = false;
        RestrictAddressFamilies = [ "AF_UNIX" "AF_INET" "AF_INET6" "AF_NETLINK" ];
        DeviceAllow = "/dev/dri";
        DevicePolicy = "closed";
        SystemCallFilter = "";
      };
    };

    xdg.desktopEntries = builtins.listToAttrs
      (
        map
          (x: {
            name = x;
            value = {
              name = x;
              exec = "";
              noDisplay = true;
            };
          }) [ "fish" "htop" "org.codeberg.dnkl.foot-server" "org.codeberg.dnkl.footclient" "umpv" ]
      ) // {
      chromium-browser = {
        name = "Chromium";
        exec = "systemd-run --user -G chromium --ozone-platform=wayland --enable-wayland-ime %U";
        icon = "chromium";
      };
      firefox = {
        name = "Firefox";
        exec = "systemd-run --user -G firefox --name firefox %U";
        icon = "firefox";
        mimeType = [ "text/html" "text/xml" "application/xhtml+xml" "application/vnd.mozilla.xul+xml" "x-scheme-handler/http" "x-scheme-handler/https" ];
      };
      imv = {
        name = "imv";
        exec = "systemd-run --user -G imv %F";
        icon = "multimedia-photo-viewer";
        mimeType = [ "image/bmp" "image/gif" "image/jpeg" "image/jpg" "image/pjpeg" "image/png" "image/tiff" "image/x-bmp" "image/x-pcx" "image/x-png" "image/x-portable-anymap" "image/x-portable-bitmap" "image/x-portable-graymap" "image/x-portable-pixmap" "image/x-tga" "image/x-xbitmap" "image/heif" ];
      };
      imv-dir = {
        name = "imv-dir";
        exec = "systemd-run --user -G imv-dir %F";
        icon = "multimedia-photo-viewer";
      };
      mpv = {
        name = "mpv";
        exec = "systemd-run --user -G mpv --player-operation-mode=pseudo-gui -- %U";
        icon = "mpv";
        mimeType = [ "application/ogg" "application/x-ogg" "application/mxf" "application/sdp" "application/smil" "application/x-smil" "application/streamingmedia" "application/x-streamingmedia" "application/vnd.rn-realmedia" "application/vnd.rn-realmedia-vbr" "audio/aac" "audio/x-aac" "audio/vnd.dolby.heaac.1" "audio/vnd.dolby.heaac.2" "audio/aiff" "audio/x-aiff" "audio/m4a" "audio/x-m4a" "application/x-extension-m4a" "audio/mp1" "audio/x-mp1" "audio/mp2" "audio/x-mp2" "audio/mp3" "audio/x-mp3" "audio/mpeg" "audio/mpeg2" "audio/mpeg3" "audio/mpegurl" "audio/x-mpegurl" "audio/mpg" "audio/x-mpg" "audio/rn-mpeg" "audio/musepack" "audio/x-musepack" "audio/ogg" "audio/scpls" "audio/x-scpls" "audio/vnd.rn-realaudio" "audio/wav" "audio/x-pn-wav" "audio/x-pn-windows-pcm" "audio/x-realaudio" "audio/x-pn-realaudio" "audio/x-ms-wma" "audio/x-pls" "audio/x-wav" "video/mpeg" "video/x-mpeg2" "video/x-mpeg3" "video/mp4v-es" "video/x-m4v" "video/mp4" "application/x-extension-mp4" "video/divx" "video/vnd.divx" "video/msvideo" "video/x-msvideo" "video/ogg" "video/quicktime" "video/vnd.rn-realvideo" "video/x-ms-afs" "video/x-ms-asf" "audio/x-ms-asf" "application/vnd.ms-asf" "video/x-ms-wmv" "video/x-ms-wmx" "video/x-ms-wvxvideo" "video/x-avi" "video/avi" "video/x-flic" "video/fli" "video/x-flc" "video/flv" "video/x-flv" "video/x-theora" "video/x-theora+ogg" "video/x-matroska" "video/mkv" "audio/x-matroska" "application/x-matroska" "video/webm" "audio/webm" "audio/vorbis" "audio/x-vorbis" "audio/x-vorbis+ogg" "video/x-ogm" "video/x-ogm+ogg" "application/x-ogm" "application/x-ogm-audio" "application/x-ogm-video" "application/x-shorten" "audio/x-shorten" "audio/x-ape" "audio/x-wavpack" "audio/x-tta" "audio/AMR" "audio/ac3" "audio/eac3" "audio/amr-wb" "video/mp2t" "audio/flac" "audio/mp4" "application/x-mpegurl" "video/vnd.mpegurl" "application/vnd.apple.mpegurl" "audio/x-pn-au" "video/3gp" "video/3gpp" "video/3gpp2" "audio/3gpp" "audio/3gpp2" "video/dv" "audio/dv" "audio/opus" "audio/vnd.dts" "audio/vnd.dts.hd" "audio/x-adpcm" "application/x-cue" "audio/m3u" ];
      };
      "org.codeberg.dnkl.foot" = {
        name = "Foot";
        exec = "systemd-run --user -G foot";
        icon = "foot";
      };
      "org.pwmt.zathura" = {
        name = "Zathura";
        exec = "systemd-run --user -G zathura %U";
        icon = "org.pwmt.zathura";
        mimeType = [ "application/pdf" "application/oxps" "application/epub+zip" "application/x-fictionbook" ];
      };
      "org.telegram.desktop" = {
        name = "Telegram Desktop";
        exec = "systemd-run --user -G telegram-desktop -- %u";
        icon = "telegram";
        mimeType = [ "x-scheme-handler/tg" ];
      };
      "org.wezfurlong.wezterm" = {
        name = "WezTerm";
        exec = "systemd-run --user -G wezterm";
        icon = "org.wezfurlong.wezterm";
      };
      thunderbird = {
        name = "Thunderbird";
        exec = "systemd-run --user -G thunderbird %U";
        icon = "thunderbird";
        mimeType = [ "message/rfc822" "x-scheme-handler/mailto" "text/calendar" "text/x-vcard" ];
      };
      dolphin = {
        name = "Dolphin";
        exec = "systemd-run --user -G dolphin %u";
        icon = "system-file-manager";
        mimeType = [ "inode/directory" ];
      };
      "org.wireshark.Wireshark" = {
        name = "Wireshark";
        exec = "systemd-run --user -G wireshark %u";
        icon = "org.wireshark.Wireshark";
        mimeType = [ "application/vnd.tcpdump.pcap" "application/x-pcapng" "application/x-snoop" "application/x-iptrace" "application/x-lanalyzer" "application/x-nettl" "application/x-radcom" "application/x-etherpeek" "application/x-visualnetworks" "application/x-netinstobserver" "application/x-5view" "application/x-tektronix-rf5" "application/x-micropross-mplog" "application/x-apple-packetlogger" "application/x-endace-erf" "application/ipfix" "application/x-ixia-vwr" ];
      };
    };

  };
}
