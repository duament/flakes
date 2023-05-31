{ config, lib, mypkgs, pkgs, sysConfig, ... }:
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

  imports = [
    ./apps.nix
  ];

  config = lib.mkIf cfg.enable {

    home.packages = with pkgs; [
      dolphin
      grim
      libsForQt5.qtstyleplugin-kvantum
      papirus-icon-theme
      thunderbird
      vulkan-validation-layers
      wl-clipboard
    ];

    home.pointerCursor = {
      package = pkgs.breeze-qt5;
      gtk.enable = true;
      name = "breeze_cursors";
    };
    home.sessionVariables.XCURSOR_SIZE = "";

    systemd.user.sessionVariables = config.home.sessionVariables // {
      QT_QPA_PLATFORM = "wayland";
      QT_QPA_PLATFORMTHEME = "qt5ct";
      QT_STYLE_OVERRIDE = "Kvantum";
      WLR_RENDERER = "vulkan";
    };

    home.activation.qt5ct = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      ln -sf ${config.xdg.dataHome}/qt5ct ${config.xdg.configHome}/
    '';

    xdg.configFile."Kvantum/Fluent-solid-pink".source = "${mypkgs.Fluent-solid-pink}/share/Kvantum/Fluent-solid-pink";
    xdg.configFile."Kvantum/kvantum.kvconfig".text = ''
      [General]
      theme=Fluent-solid-pink
    '';

    gtk = {
      enable = true;
      font.name = "sans-serif";
      inherit iconTheme;
    };

    programs.swaylock = {
      enable = true;
      settings = {
        image = wallpaper-cloud.outPath;
        indicator-caps-lock = true;
        inside-color = "00000000";
        inside-clear-color = "00000000";
        inside-caps-lock-color = "00000000";
        inside-ver-color = "00000000";
        inside-wrong-color = "00000000";
        line-color = "00000000";
        line-clear-color = "00000000";
        line-caps-lock-color = "00000000";
        line-ver-color = "00000000";
        line-wrong-color = "00000000";
        separator-color = "00000000";
        ring-color = "F5C2E7";
        ring-clear-color = "FAB387";
        ring-caps-lock-color = "617A55";
        ring-ver-color = "93BFCF";
        ring-wrong-color = "E96479";
        key-hl-color = "9DC08B";
        caps-lock-key-hl-color = "9DC08B";
        bs-hl-color = "E96479";
        caps-lock-bs-hl-color = "E96479";
        text-caps-lock-color = "617A55";
      };
    };
    services.swayidle = {
      enable = true;
      systemdTarget = "graphical-session.target";
      timeouts = [
        { timeout = 600; command = "${config.programs.swaylock.package}/bin/swaylock &"; }
        { timeout = 610; command = "${sysConfig.programs.hyprland.package}/bin/hyprctl dispatch dpms off"; resumeCommand = "${sysConfig.programs.hyprland.package}/bin/hyprctl dispatch dpms on"; }
      ];
      events = [
        { event = "lock"; command = "${config.programs.swaylock.package}/bin/swaylock &"; }
        { event = "before-sleep"; command = "${config.programs.swaylock.package}/bin/swaylock &"; }
      ];
    };
    systemd.user.services.swayidle.Unit.After = [ "graphical-session.target" ];

    xdg.configFile."hypr/hyprland.conf" = {
      text = ''
        ${builtins.readFile ./hyprland.conf}
        bind = $mainMod, L, exec, ${config.programs.swaylock.package}/bin/swaylock
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
    systemd.user.services.waybar = {
      Unit = {
        Wants = [ "hyprland-session.target" ];
        After = lib.mkForce [ "hyprland-session.target" ];
        Before = [ "graphical-session.target" ];
        PartOf = lib.mkForce [ ];
      };
      Service = {
        Type = "dbus";
        BusName = "fr.arouillard.waybar";
      };
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
      package = pkgs.wezterm.overrideAttrs (old: {
        patches = (old.patches or [ ]) ++ [
          ./wezterm-scroll.patch
        ];
      });
      extraConfig = builtins.readFile ./wezterm.lua;
    };

    systemd.user.services.kdeconnect.Unit.After = [ "graphical-session.target" ];
    systemd.user.services.kdeconnect-indicator.Unit.After = [ "graphical-session.target" ];

  };
}
