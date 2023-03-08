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
      keepassxc
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
      config = rec {
        fullscreen = true;
        ao = "pipewire";
        vo = "gpu-next";
        hwdec = "vaapi";
        gpu-api = "vulkan";
        gpu-context = "waylandvk";
        profile = "gpu-hq";
        slang-append = [ "zh-Hans" "zh-CN" "zh" "chi" "zh-Hant" "zh-TW" "zh-HK" "en-US" "en-GB" "en" ];
        audio-file-auto = "fuzzy";
        sub-auto = "fuzzy";
        sub-font-size = 36;
        sub-border-size = 0;
        sub-shadow-color = "#000000";
        sub-shadow-offset = 1;
        video-align-y = -1;
        sub-ass-force-margins = true;
        audio-display = false;
        ytdl-raw-options-append = [
          "format=bestvideo[height<=1440][fps>=60]+bestaudio/bestvideo[height<=1440]+bestaudio/best[height<=1440]/best"
          "write-sub="
          "sub-lang=${builtins.concatStringsSep "," slang-append}"
        ];
      };
    };
  };
}
