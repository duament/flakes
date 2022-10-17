{ config, lib, ... }:
with lib;
{
  options = {
    presets.workstation.enable = mkOption {
      type = types.bool;
      default = false;
    };
  };

  config = mkIf config.presets.workstation.enable {
    presets.ssh-agent.enable = true;
    presets.chromium.enable = true;

    hardware.enableRedistributableFirmware = true;

    boot.loader.grub.enable = false;

    networking.networkmanager.enable = true;

    services.xserver.enable = true;
    services.xserver.displayManager.gdm.enable = true;
    services.xserver.desktopManager.gnome.enable = true;

    xdg.portal.enable = true;

    security.rtkit.enable = true;
    hardware.pulseaudio.enable = false;
    services.pipewire = {
      enable = true;
      #alsa.enable = true;
      #alsa.support32Bit = true;
      pulse.enable = true;
      #jack.enable = true;
    };

    services.pcscd.enable = true;
    programs.gnupg.agent.enable = true;
  };
}
