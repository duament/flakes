{ config, pkgs }:
{
  input.touchpad.natural_scroll = true;

  general = {
    sensitivity = 1.0; # for mouse cursor
    gaps_in = 5;
    gaps_out = 10;
    border_size = 5;
    "col.active_border" = "0xfff5c2e7";
    "col.inactive_border" = "0xff45475a";
    apply_sens_to_raw = 0; # whether to apply the sensitivity to raw input (e.g. used by games where you aim using your mouse)
  };

  decoration = {
    drop_shadow = true;
    shadow_range = 20;
    shadow_render_power = 5;
    "col.shadow" = "0x30000000";
    "col.shadow_inactive" = "0x20000000";
    rounding = 15;
    blur = {
      size = 2;
      passes = 1;
    };
  };

  animations = {
    enabled = 1;
    bezier = "easeOutCirc, 0, 0.55, 0.45, 1";
    animation = [
      "windows, 1, 4, default, popin 80%"
      "border, 1, 10, default"
      "fade, 1, 5, default"
      "workspaces, 1, 5, default, slidevert"
    ];
  };

  dwindle = {
    pseudotile = true; # enable pseudotiling on dwindle
    preserve_split = true;
  };

  gestures = {
    workspace_swipe = true;
    workspace_swipe_fingers = 4;
    workspace_swipe_distance = 200;
  };

  group = {
    "col.border_inactive" = "0xff89dceb";
    "col.border_active" = "0xfff9e2af";
    groupbar = {
      gradients = false;
      font_size = 24;
    };
  };

  misc = {
    mouse_move_enables_dpms = true;
    vrr = 1;
  };

  xwayland.force_zero_scaling = true;

  "$mainMod" = "SUPER";

  bind = [
    "$mainMod, RETURN, exec, systemd-run --user -G -u wezterm-$RANDOM wezterm"
    "$mainMod, C, killactive,"
    "$mainMod, M, exit,"
    "$mainMod, E, exec, systemd-run --user -G -u dolphin-$RANDOM -E QT_IM_MODULE=fcitx dolphin"
    "$mainMod, F, togglefloating,"
    "$mainMod, R, exec, wofi --show drun"
    "$mainMod, P, pseudo, # dwindle"
    "$mainMod, J, togglesplit, # dwindle"
    "$mainMod, L, exec, ${config.programs.swaylock.package}/bin/swaylock"
    "$mainMod, S, exec, ${pkgs.grim}/bin/grim -g \"$(${pkgs.slurp}/bin/slurp)\""

    # Move focus with mainMod + arrow keys
    "$mainMod, left, movefocus, l"
    "$mainMod, right, movefocus, r"
    "$mainMod, up, movefocus, u"
    "$mainMod, down, movefocus, d"

    # Move active workspace to a monitor
    "$mainMod SHIFT, left, movecurrentworkspacetomonitor, l"
    "$mainMod SHIFT, right, movecurrentworkspacetomonitor, r"
    "$mainMod SHIFT, up, movecurrentworkspacetomonitor, u"
    "$mainMod SHIFT, down, movecurrentworkspacetomonitor, d"

    # Switch workspaces with mainMod + [0-9]
    "$mainMod, 1, workspace, 1"
    "$mainMod, 2, workspace, 2"
    "$mainMod, 3, workspace, 3"
    "$mainMod, 4, workspace, 4"
    "$mainMod, 5, workspace, 5"
    "$mainMod, 6, workspace, 6"
    "$mainMod, 7, workspace, 7"
    "$mainMod, 8, workspace, 8"
    "$mainMod, 9, workspace, 9"
    "$mainMod, 0, workspace, 10"

    # Move active window to a workspace with mainMod + SHIFT + [0-9]
    "$mainMod SHIFT, 1, movetoworkspace, 1"
    "$mainMod SHIFT, 2, movetoworkspace, 2"
    "$mainMod SHIFT, 3, movetoworkspace, 3"
    "$mainMod SHIFT, 4, movetoworkspace, 4"
    "$mainMod SHIFT, 5, movetoworkspace, 5"
    "$mainMod SHIFT, 6, movetoworkspace, 6"
    "$mainMod SHIFT, 7, movetoworkspace, 7"
    "$mainMod SHIFT, 8, movetoworkspace, 8"
    "$mainMod SHIFT, 9, movetoworkspace, 9"
    "$mainMod SHIFT, 0, movetoworkspace, 10"

    # Scroll through existing workspaces with mainMod + scroll
    "$mainMod, mouse_down, workspace, e-1"
    "$mainMod, mouse_up, workspace, e+1"
    "$mainMod, tab, workspace, e+1"
    "$mainMod SHIFT, tab, workspace, e-1"

    # Group
    "$mainMod, g, togglegroup"
    "SHIFT, left, changegroupactive, b"
    "SHIFT, right, changegroupactive, f"
  ];

  # Move/resize windows with mainMod + LMB/RMB and dragging
  bindm = [
    "$mainMod, mouse:272, movewindow"
    "$mainMod, mouse:273, resizewindow"
  ];

  binde = [
    ", XF86AudioRaiseVolume, exec, wpctl set-volume -l 1.5 @DEFAULT_AUDIO_SINK@ 2%+"
    ", XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 2%-"
    ", XF86MonBrightnessUp, exec, brightnessctl set +5%"
    ", XF86MonBrightnessDown, exec, brightnessctl set 5%-"
  ];

  windowrulev2 = [
    "float, class:^(imv)$"
    "float, class:^(pavucontrol)$"
    "float, class:^(org.telegram.desktop)$, title:^(Media viewer)$"
    "float, class:^(firefox)$, title:^(Picture-in-Picture)$"
    "float, class:^(org.kde.kdeconnect-indicator)$"
    "float, class:^(org.kde.kdeconnect.handler)$"
    "float, class:^(org.kde.dolphin)$"
    "group set, workspace:1"
  ] ++ (builtins.genList (i: let n = toString (i + 1); in "workspace ${n}, cgroup2:^(.*)(-w${n}\.service)$") 9);

  exec-once = [
  ];
}
