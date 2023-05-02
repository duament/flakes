{ config, lib, self, ... }:
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

  services.syncthing = {
    enable = true;
    openDefaultPorts = true;
    cert = config.sops.secrets."syncthing/cert".path;
    key = config.sops.secrets."syncthing/key".path;
    devices = self.data.syncthing.devices;
    folders = lib.getAttrs [ "keepass" "notes" "session" ] self.data.syncthing.folders;
  };
  systemd.tmpfiles.rules = [ "d ${config.services.syncthing.dataDir} 2770 syncthing syncthing -" "a ${config.services.syncthing.dataDir} - - - - d:g::rwx" ];
  users.users.rvfg.extraGroups = [ "syncthing" ];
}
