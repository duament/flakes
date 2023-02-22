{ config, pkgs, ... }:
let
  host = "desktop";
in
{
  presets.workstation.enable = true;

  sops.defaultSopsFile = ./secrets.yaml;
  sops.secrets = {
    "sbsign-key" = { };
    "sbsign-cert" = { };
    clash = {
      format = "binary";
      sopsFile = ../../secrets/clash;
    };
    wireguard_key.owner = "systemd-network";
  };

  presets.refind = {
    signKey = config.sops.secrets."sbsign-key".path;
    signCert = config.sops.secrets."sbsign-cert".path;
    configurationLimit = 10;
  };

  networking.hostName = host;
  networking.useDHCP = false;
  networking.networkmanager = {
    enable = true;
    unmanaged = [ "wg0" ];
    dns = "systemd-resolved";
  };
  home-manager.users.rvfg = import ./home.nix;

  systemd.tmpfiles.rules = [ "L+ /run/gdm/.config/monitors.xml - - - - ${./monitors.xml}" ];

  services.xserver.enable = true;
  services.xserver.displayManager.gdm.enable = true;
  services.xserver.desktopManager.gnome.enable = true;

  services.clash.enable = true;
  services.clash.configFile = config.sops.secrets.clash.path;
}
