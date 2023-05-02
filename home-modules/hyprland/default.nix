{ config, lib, pkgs, self, sysConfig, ... }:
let
  cfg = config.presets.hyprland;

  iconTheme = {
    package = pkgs.papirus-icon-theme;
    name = "Papirus";
  };

  wallpaper-cloud = pkgs.fetchurl {
    url = "https://github.com/flick0/dotfiles/raw/dreamy/config/hypr/wallpapers/cloud.png";
    name = "cloud.png";
    hash = "sha256-N3+6n+/zOq/A4B9hdTD8pQClNNp9Gqa+koubWrf7J6k=";
  };
in
{
  options = {
    presets.hyprland.enable = lib.mkEnableOption "hyprland presets";
  };

  config = lib.mkIf cfg.enable {

    home.packages = with pkgs; [
      grim
      papirus-icon-theme
      thunderbird
      vulkan-validation-layers
      wl-clipboard
    ];

    home.pointerCursor = {
      package = pkgs.breeze-qt5;
      gtk.enable = true;
      name = "breeze_cursors";
      size = 48;
    };

    systemd.user.sessionVariables = config.home.sessionVariables // {
      QT_STYLE_OVERRIDE = "Breeze";
      QT_QPA_PLATFORM = "wayland";
      WLR_RENDERER = "vulkan";
    };

    gtk = {
      enable = true;
      font.name = "sans-serif";
      inherit iconTheme;
    };

    services.swayidle = {
      enable = true;
      systemdTarget = "graphical-session.target";
      timeouts = [
        { timeout = 600; command = "${pkgs.swaylock}/bin/swaylock"; }
        { timeout = 630; command = "${sysConfig.programs.hyprland.package}/bin/hyprctl dispatch dpms off"; resumeCommand = "${sysConfig.programs.hyprland.package}/bin/hyprctl dispatch dpms on"; }
      ];
      events = [
        { event = "lock"; command = "${pkgs.swaylock}/bin/swaylock"; }
      ];
    };
    systemd.user.services.swayidle.Unit.After = [ "graphical-session.target" ];

    xdg.configFile."hypr/hyprland.conf" = {
      text = ''
        ${builtins.readFile ./hyprland.conf}
        bind = $mainMod, L, exec, ${pkgs.swaylock}/bin/swaylock
        bind = $mainMod, S, exec, ${pkgs.grim}/bin/grim -g "$(${pkgs.slurp}/bin/slurp)"
        exec-once = systemctl --user import-environment DISPLAY WAYLAND_DISPLAY HYPRLAND_INSTANCE_SIGNATURE XDG_CURRENT_DESKTOP && systemd-notify --ready
        exec-once = systemd-run --user -G -u wezterm ${config.programs.wezterm.package}/bin/wezterm
        exec-once = systemd-run --user -G -u firefox ${config.programs.firefox.package}/bin/firefox
        exec-once = systemd-run --user -G -u thunderbird thunderbird
      '';
      onChange = ''
        (  # execute in subshell so that `shopt` won't affect other scripts
          shopt -s nullglob  # so that nothing is done if /tmp/hypr/ does not exist or is empty
          for instance in /tmp/hypr/*; do
            HYPRLAND_INSTANCE_SIGNATURE=''${instance##*/} ${sysConfig.programs.hyprland.package}/bin/hyprctl reload config-only \
              || true  # ignore dead instance(s)
          done
        )
      '';
    };
    systemd.user.services.hyprland = {
      Unit = {
        Wants = [ "graphical-session-pre.target" ];
        After = [ "graphical-session-pre.target" ];
        BindsTo = [ "graphical-session.target" ];
        Before = [ "graphical-session.target" ];
      };
      Service = {
        Type = "notify";
        NotifyAccess = "all";
        ExecStart = "${sysConfig.programs.hyprland.package}/bin/Hyprland";
        ExecStopPost = "/run/current-system/sw/bin/systemctl --user unset-environment DISPLAY WAYLAND_DISPLAY XDG_CURRENT_DESKTOP XDG_SESSION_TYPE XDG_SESSION_DESKTOP";
        Restart = "on-failure";
        RestartSec = 1;
      };
    };
    systemd.user.targets.hyprland-session = {
      Unit = {
        BindsTo = [ "graphical-session-pre.target" ];
        After = [ "graphical-session-pre.target" "hyprland.service" ];
      };
    };
    systemd.user.services.fcitx5-daemon.Unit = {
      Wants = [ "hyprland-session.target" ];
      After = [ "hyprland-session.target" ];
      Before = [ "graphical-session.target" ];
    };
    systemd.user.services.swww = {
      Unit = {
        Wants = [ "hyprland-session.target" ];
        After = [ "hyprland-session.target" ];
      };
      Service.ExecStart = "${pkgs.swww}/bin/swww-daemon";
      Service.ExecStartPost = "/bin/sh -c \"sleep 1 && ${pkgs.swww}/bin/swww img ${wallpaper-cloud} --transition-type grow --transition-duration 3\"";
      Install.WantedBy = [ "graphical-session.target" ];
    };

    programs.waybar = {
      enable = true;
      package = pkgs.waybar.overrideAttrs (oldAttrs: {
        postPatch = ''
          sed -i 's/zext_workspace_handle_v1_activate(workspace_handle_);/const std::string command = "hyprctl dispatch workspace " + name_;\n\tsystem(command.c_str());/g' src/modules/wlr/workspace_manager.cpp
        '';
        mesonFlags = oldAttrs.mesonFlags ++ [ "-Dexperimental=true" ];
      });
      systemd.enable = true;
      settings = [ (import ./waybar.nix { inherit pkgs; }) ];
      style = builtins.readFile ./waybar.css;
    };

    programs.wofi = {
      enable = true;
      settings = {
        width = 400;
        height = 250;
        location = "center";
        show = "drun";
        prompt = "Search...";
        filter_rate = 100;
        allow_markup = true;
        no_actions = true;
        halign = "fill";
        orientation = "vertical";
        content_halign = "fill";
        insensitive = true;
        allow_images = true;
        image_size = 40;
        gtk_dark = true;
      };
      style = builtins.readFile ./wofi.css;
    };

    services.dunst = {
      enable = true;
      inherit iconTheme;
      settings = {
        global = {
          monitor = 0;
          follow = "none";
          width = 600;
          height = 200;
          origin = "top-right";
          offset = "20x20";
          scale = 0;
          notification_limit = 0;
          progress_bar = true;
          progress_bar_height = 10;
          progress_bar_frame_width = 1;
          progress_bar_min_width = 150;
          progress_bar_max_width = 300;
          indicate_hidden = "yes";
          transparency = 0;
          separator_height = 2;
          padding = 8;
          horizontal_padding = 8;
          text_icon_padding = 0;
          frame_width = 3;
          frame_color = "#c0caf5";
          gap_size = 5;
          separator_color = "frame";
          sort = "yes";
          font = "sans-serif 16";
          line_height = 0;
          markup = "full";
          format = "<b>%s</b>\\n%b";
          alignment = "left";
          vertical_alignment = "center";
          show_age_threshold = 60;
          ellipsize = "end";
          ignore_newline = "no";
          stack_duplicates = true;
          hide_duplicate_count = false;
          show_indicators = "yes";
          icon_position = "left";
          min_icon_size = 32;
          max_icon_size = 64;
          icon_theme = "Papirus";
          enable_recursive_icon_lookup = true;
          sticky_history = "yes";
          history_length = 20;
          #dmenu = /usr/bin/dmenu -p dunst:;
          #browser = /usr/bin/xdg-open;
          title = "Dunst";
          class = "Dunst";
          corner_radius = 15;
          ignore_dbusclose = false;
          mouse_left_click = "close_current";
          mouse_middle_click = "context";
          mouse_right_click = "do_action";
        };
      };
    };
    systemd.user.services.dunst.Service.UnsetEnvironment = [ "XCURSOR_SIZE" ];

    programs.foot = {
      enable = true;
      settings = {
        main = {
          font = "monospace:size=9";
          dpi-aware = "yes";
        };
        colors = {
          foreground = "383A42";
          background = "F7F8FA";
          regular0 = "2E3440";
          regular1 = "CB4F53";
          regular2 = "48A53D";
          regular3 = "EE5E25";
          regular4 = "3879C5";
          regular5 = "9F4ACA";
          regular6 = "3EA1AD";
          regular7 = "E5E9F0";
          bright0 = "646A76";
          bright1 = "D16366";
          bright2 = "5F9E9D";
          bright3 = "BA793E";
          bright4 = "1B40A6";
          bright5 = "9665AF";
          bright6 = "8FBCBB";
          bright7 = "ECEFF4";
        };
      };
    };

    programs.wezterm = {
      enable = true;
      extraConfig = builtins.readFile ./wezterm.lua;
    };

    systemd.user.tmpfiles.rules = [
      "d %h/.cache/keepassxc - - - -"
      "d %h/.local/share/keepassxc - - - -"
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
      };
    };

  };
}
