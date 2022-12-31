{ config, lib, pkgs, ... }:
with lib;
{
  options = {
    presets.workstation.enable = mkOption {
      type = types.bool;
      default = false;
    };
  };

  config = mkIf config.presets.workstation.enable {
    presets.ssh.enable = true;
    presets.browser.enable = true;
    presets.python.enable = true;

    home.packages = with pkgs; [
      gnome.gnome-tweaks
      gnomeExtensions.appindicator
      sops
      tdesktop
      unar
      usbutils
      wireguard-tools
    ];

    presets.git.enable = true;
    programs.git.extraConfig.gcrypt = {
      participants = "F2E3DA8DE23F4EA11033EDEC535D184864C05736";
      publish-participants = true;
    };

    programs.gpg.enable = true;

    programs.mpv = {
      enable = true;
      config = {
        fullscreen = true;
      };
    };
  };
}
