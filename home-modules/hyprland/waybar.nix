{ pkgs }:
{
  layer = "top"; # Waybar at top layer
  position = "top"; # Waybar position (top|bottom|left|right)
  height = 50; # Waybar height (to be removed for auto height)
  spacing = 5; # Gaps between modules (4px)
  margin-bottom = -11;
  modules-left = [ "hyprland/workspaces" ];
  modules-right = [ "tray" "pulseaudio" "network" "battery" "backlight" "clock" "keyboard-state" ];
  modules-center = [ "hyprland/window" ];

  keyboard-state = {
    capslock = true;
    format = "{icon}";
    format-icons = {
      locked = "󰪛";
      unlocked = "";
    };
    #device-path = "/dev/input/by-path/platform-i8042-serio-0-event-kbd";
  };
  "hyprland/workspaces" = {
    on-click = "activate";
  };
  "hyprland/window" = {
    format = "{}";
    separate-outputs = true;
  };
  idle_inhibitor = {
    format = "{icon}";
    format-icons = {
      activated = "";
      deactivated = "";
    };
  };
  tray = {
    # icon-size = 21;
    spacing = 10;
  };
  clock = {
    tooltip-format = "<big>{:%Y-%m-%d}</big>\n<tt><small>{calendar}</small></tt>";
    interval = 60;
    format = "{:%H:%M}";
    format-alt = "{:%Y-%m-%d}";
  };
  cpu = {
    interval = 1;
    format = "{icon0} {icon1} {icon2} {icon3}";
    format-icons = [ "▁" "▂" "▃" "▄" "▅" "▆" "▇" "█" ];
  };
  memory = {
    format = "{}% ";
  };
  temperature = {
    critical-threshold = 80;
    format-critical = "{temperatureC}°C";
    format = "";
  };
  backlight = {
    format = "{icon}";
    format-icons = [ "" "" "" "" "" "" "" "" "" ];
    tooltip-format = "{percent}%";
  };
  battery = {
    bat = "BAT0";
    adapter = "ADP0";
    states = {
      warning = 50;
      critical = 20;
    };
    format = "{icon}";
    format-charging = "{icon}";
    format-plugged = "";
    format-icons = [ "󰁺" "󰁻" "󰁼" "󰁽" "󰁾" "󰁿" "󰂀" "󰂁" "󰂂" "󰁹" ];
    tooltip-format = "{timeTo} ({capacity}%)";
  };
  network = {
    format-icons = [ "󰤟" "󰤢" "󰤥" "󰤨" ];
    format-wifi = "{icon}";
    format-ethernet = "󰈀";
    tooltip-format = "{essid} ({signalStrength}%) via {ifname}";
    format-linked = "";
    format-disconnected = "󰤭";
    format-alt = "   ";
  };
  pulseaudio = {
    # scroll-step = 1;  # %, can be a float
    format = "{icon} {volume}";
    format-bluetooth = "{icon}  {volume}";
    format-bluetooth-muted = "󰝟  {volume}";
    format-muted = "󰝟 {volume}";
    format-icons = {
      headphone = "󰋋";
      hands-free = "󰋋";
      headset = "󰋋";
      phone = "";
      portable = "";
      car = "";
      default = [ "" "" "" ];
    };
    on-click = "${pkgs.pavucontrol}/bin/pavucontrol";
  };
}
