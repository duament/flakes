{ config, lib, pkgs, self, sysConfig, ... }: {
  imports = [
    self.nixosModules.myHomeModules
  ];

  presets.workstation.enable = true;

  home.packages = with pkgs; [
    brightnessctl
    grim
    openssl
    papirus-icon-theme
    swww
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
    WLR_RENDERER = "vulkan";
  };

  gtk = {
    enable = false;
    iconTheme = {
      package = pkgs.papirus-icon-theme;
      name = "Papirus";
    };
  };

  wayland.windowManager.sway = {
    enable = false;
    wrapperFeatures.gtk = true;
    systemdIntegration = true;
    config = rec {
      modifier = "Mod4";
      terminal = "systemd-run --user -G -u foot-$RANDOM foot";
      assigns = {
        "1" = [{ app_id = "org.wezfurlong.wezterm"; }];
        "2" = [{ app_id = "firefox"; title = "Mozilla Firefox$"; }];
        "3" = [{ app_id = "firefox"; title = "Mozilla Firefox Private Browsing$"; }];
        "4" = [{ app_id = "org.keepassxc.KeePassXC"; }];
        "5" = [{ app_id = "org.telegram.desktop"; }];
      };
      bars = [ ];
      keybindings = lib.mkOptionDefault {
        "${modifier}+space" = null;
        "${modifier}+v" = null;
      };
      input = {
        "1267:12600:MSFT0001:00_04F3:3138_Touchpad" = {
          natural_scroll = "enabled";
          tap = "enabled";
        };
      };
      output.eDP-1 = {
        scale = "2";
      };
    };
    extraConfig = ''
      exec systemd-notify --ready
      exec systemd-run --user -G -u wezterm wezterm
      exec ~/files/kp
      exec systemd-run --user -G -u firefox firefox
      exec ~/files/tg
    '';
  };
  systemd.user.services.sway = {
    Unit = {
      Wants = [ "graphical-session-pre.target" ];
      After = [ "graphical-session-pre.target" ];
      BindsTo = [ "graphical-session.target" ];
      Before = [ "graphical-session.target" ];
    };
    Service = {
      Type = "notify";
      NotifyAccess = "all";
      ExecStart = "${config.wayland.windowManager.sway.package}/bin/sway";
      ExecStopPost = "/run/current-system/sw/bin/systemctl --user unset-environment SWAYSOCK DISPLAY WAYLAND_DISPLAY XDG_CURRENT_DESKTOP XDG_SESSION_TYPE XDG_SESSION_DESKTOP";
      Restart = "on-failure";
      RestartSec = 1;
    };
  };
  services.swayidle = {
    enable = true;
    timeouts = [
      { timeout = 900; command = "${pkgs.swaylock}/bin/swaylock"; }
      { timeout = 905; command = ''swaymsg "output * dpms off"''; resumeCommand = ''swaymsg "output * dpms on"''; }
    ];
    events = [
      { event = "lock"; command = "${pkgs.swaylock}/bin/swaylock"; }
    ];
  };

  xdg.configFile."hypr/hyprland.conf" = {
    text = ''
      ${builtins.readFile ./hyprland.conf}
      bind = $mainMod, L, exec, ${pkgs.swaylock}/bin/swaylock
      bind = $mainMod, S, exec, ${pkgs.grim}/bin/grim -g "$(${pkgs.slurp}/bin/slurp)"
      exec-once = systemctl --user import-environment DISPLAY WAYLAND_DISPLAY HYPRLAND_INSTANCE_SIGNATURE XDG_CURRENT_DESKTOP && systemd-notify --ready
      # exec-once = ~/files/dreamy/scripts/tools/dynamic
      exec-once = systemd-run --user -G -u wezterm wezterm
      exec-once = ~/files/kp
      exec-once = systemd-run --user -G -u firefox firefox
      exec-once = ~/files/tg
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
    Service.Type = "forking";
    Service.ExecStart = "${pkgs.swww}/bin/swww init";
    Service.ExecStartPost = "/bin/sh -c \"sleep 1 && swww img ~/files/dreamy/wallpapers/cloud.png --transition-type grow --transition-pos \\\"$(hyprctl cursorpos)\\\" --transition-duration 3\"";
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
    systemd = {
      enable = true;
      #target = "sway-session.target";
    };
    settings = [ (import ./waybar.nix { inherit pkgs; }) ];
    style = builtins.readFile ./waybar.css;
  };

  programs.foot = {
    enable = true;
    server.enable = true;
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
    extraConfig = ''
      local wezterm = require 'wezterm'
      local config = wezterm.config_builder()

      config.color_scheme = 'OneHalfLight'

      config.font = wezterm.font_with_fallback {
        'Hack',
        'Noto Sans CJK SC',
        'Noto Color Emoji',
        'Symbols Nerd Font Mono',
      }

      config.window_frame = {
        font = wezterm.font_with_fallback {
          { family = 'Inter', weight = 'Medium' },
          { family = 'Noto Sans CJK SC', weight = 'Medium' },
        },
        active_titlebar_bg = '#e6e6e6',
        inactive_titlebar_bg = '#e6e6e6',
      }

      config.colors = {
        tab_bar = {
          inactive_tab_edge = '#cdcdcd',
          active_tab = {
            bg_color = '#fafafa',
            fg_color = '#000000',
          },
          inactive_tab = {
            bg_color = '#d7d7d7',
            fg_color = '#4d4d4d',
          },
          inactive_tab_hover = {
            bg_color = '#c0c0c0',
            fg_color = '#404040',
          },
          new_tab = {
            bg_color = '#d7d7d7',
            fg_color = '#333333',
          },
          new_tab_hover = {
            bg_color = '#c0c0c0',
            fg_color = '#404040',
          },
        },
        scrollbar_thumb = '#d7d7d7',
      }

      config.keys = {
        { key = 'LeftArrow', mods = 'SHIFT', action = wezterm.action.ActivateTabRelative(-1) },
        { key = 'RightArrow', mods = 'SHIFT', action = wezterm.action.ActivateTabRelative(1) },
      }

      config.enable_scroll_bar = true
      config.scrollback_lines = 10000
      config.alternate_buffer_wheel_scroll_speed = 1

      config.mouse_bindings = {
        {
          event = { Down = { streak = 1, button = { WheelUp = 1 } } },
          mods = 'NONE',
          action = wezterm.action_callback(function(window, pane)
            local delta = window:current_event().Down.button.WheelUp
            local total = (wezterm.GLOBAL.scroll_up or 0) + delta
            local step = total // 10
            wezterm.GLOBAL.scroll_down = 0
            wezterm.GLOBAL.scroll_up = total - step * 10
            window:perform_action(wezterm.action.ScrollByLine(-step), pane)
          end),
        },
        {
          event = { Down = { streak = 1, button = { WheelDown = 1 } } },
          mods = 'NONE',
          action = wezterm.action_callback(function(window, pane)
            local delta = window:current_event().Down.button.WheelDown
            local total = (wezterm.GLOBAL.scroll_down or 0) + delta
            local step = total // 10
            wezterm.GLOBAL.scroll_up = 0
            wezterm.GLOBAL.scroll_down = total - step * 10
            window:perform_action(wezterm.action.ScrollByLine(step), pane)
          end),
        },
      }

      return config
    '';
  };
}
