{ config, pkgs, self, ... }: {
  imports = [
    self.nixosModules.myHomeModules
  ];

  presets.workstation.enable = true;

  home.packages = with pkgs; [
    brightnessctl
    openssl
    breeze-icons
  ];

  systemd.user.sessionVariables = {
  };

  wayland.windowManager.sway = {
    enable = true;
    wrapperFeatures.gtk = true;
    systemdIntegration = true;
    config = {
      modifier = "Mod4";
      terminal = "foot";
      bars = [ ];
      input = {
        "1267:12600:MSFT0001:00_04F3:3138_Touchpad" = {
          natural_scroll = "enabled";
          tap = "enabled";
        };
      };
      output.eDP-1 = {
        scale = "2";
      };
      seat."*".xcursor_theme = "Breeze 48";
    };
    extraConfig = "exec systemd-notify --ready";
  };
  systemd.user.services.sway = {
    Unit = {
      BindsTo = [ "graphical-session.target" ];
      Wants = [ "graphical-session-pre.target" ];
      After = [ "graphical-session-pre.target" ];
    };
    Service = {
      Type = "notify";
      NotifyAccess = "all";
      ExecStart = "${config.wayland.windowManager.sway.package}/bin/sway";
      ExecStopPost = "/run/current-system/sw/bin/systemctl --user unset-environment SWAYSOCK DISPLAY I3SOCK WAYLAND_DISPLAY XDG_CURRENT_DESKTOP XDG_SESSION_TYPE XDG_SESSION_DESKTOP";
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
  programs.waybar = {
    enable = true;
    systemd = {
      enable = true;
      target = "sway-session.target";
    };
    settings = { };
    style = "";
  };

  programs.foot = {
    enable = true;
    server.enable = true;
    settings = {
      main = {
        #font = "monospace:size=11";
        dpi-aware = "yes";
      };
      colors = {
        foreground = "6A6F77";
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
}
