{ config, lib, pkgs, self, ... }:
let
  cfg = config.presets.hyprland;
in
{
  config = lib.mkIf cfg.enable {
    systemd.user.tmpfiles.rules = [
      "d %h/.cache/keepassxc - - - -"
      "d %h/.local/share/keepassxc - - - -"
      "d %h/.mozilla/native-messaging-hosts - - - -"
    ] ++ [
      "d %h/.local/share/TelegramDesktop - - - -"
      "d %h/Downloads/Telegram\\ Desktop - - - -"
    ];

    systemd.user.services.keepassxc = {
      Unit.After = [ "graphical-session.target" ];
      Install.WantedBy = [ "graphical-session.target" ];
      Service = self.data.systemdHarden // {
        UnsetEnvironment = [ "XCURSOR_SIZE" ];
        Environment = [ "QT_QPA_PLATFORM=wayland" ];
        BindPaths = [ "%t" "%h/.local/share/keepassxc:%h/.config/keepassxc" "%h/.cache/keepassxc" "-/var/lib/syncthing" "-%h/.mozilla/native-messaging-hosts" "-%h/.config/chromium/NativeMessagingHosts" ];
        BindReadOnlyPaths = [ "/nix" "/run/opengl-driver" "/run/current-system" "-%h/.config/fontconfig" ];
        ExecStart = "${pkgs.keepassxc}/bin/keepassxc";
        ProtectHome = "tmpfs";
        DynamicUser = false;
        PrivateDevices = false;
        PrivateNetwork = false;
        PrivateIPC = false;
        RestrictAddressFamilies = [ "AF_UNIX" "AF_INET" "AF_INET6" "AF_NETLINK" ];
        DeviceAllow = "/dev/dri";
        DevicePolicy = "closed";
      };
    };

    systemd.user.services.telegram = {
      Unit.After = [ "graphical-session.target" ];
      Install.WantedBy = [ "graphical-session.target" ];
      Service = self.data.systemdHarden // {
        UnsetEnvironment = [ "XCURSOR_SIZE" ];
        Environment = [ "QT_QPA_PLATFORM=wayland" ];
        MemoryHigh = "2G";
        BindPaths = [ "%t" "%h/.local/share/TelegramDesktop" "%h/Downloads/Telegram\\ Desktop" ];
        BindReadOnlyPaths = [ "/nix" "/run/opengl-driver" "/run/current-system" "-%h/.config/fontconfig" ];
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

  };
}
