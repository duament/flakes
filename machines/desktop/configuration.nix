{ config, ... }:
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
    "syncthing/cert".owner = config.services.syncthing.user;
    "syncthing/key".owner = config.services.syncthing.user;
  };

  presets.refind = {
    signKey = config.sops.secrets."sbsign-key".path;
    signCert = config.sops.secrets."sbsign-cert".path;
    configurationLimit = 10;
  };

  networking = {
    hostName = "desktop";
    useDHCP = false;
    useNetworkd = true;
  };

  systemd.network.networks."80-ethernet" = {
    enable = true;
    matchConfig = { Type = "ether"; };
    DHCP = "yes";
    dhcpV6Config.UseDelegatedPrefix = false;
    domains = [ "~h.rvf6.com" ];
  };

  home-manager.users.rvfg = import ./home.nix;

  services.clash.enable = true;
  services.clash.configFile = config.sops.secrets.clash.path;
}
