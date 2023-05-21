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
    "eap/ca" = { };
    "eap/xiaoxin-bundle" = { };
    "eap/xiaoxin-key" = { };
    "syncthing/cert".owner = config.services.syncthing.user;
    "syncthing/key".owner = config.services.syncthing.user;
  };

  presets.refind = {
    signKey = config.sops.secrets."sbsign-key".path;
    signCert = config.sops.secrets."sbsign-cert".path;
    configurationLimit = 3;
  };

  networking = {
    hostName = "xiaoxin";
    useDHCP = false;
    useNetworkd = true;
    wireless = {
      enable = true;
      userControlled = {
        enable = true;
        group = "rvfg";
      };
      networks.rvfg-wpa2 = {
        authProtocols = [ "WPA-EAP" ];
        auth = ''
          eap=TLS
          identity="xiaoxin"
          ca_cert="${config.sops.secrets."eap/ca".path}"
          client_cert="${config.sops.secrets."eap/xiaoxin-bundle".path}"
          private_key="${config.sops.secrets."eap/xiaoxin-key".path}"
        '';
      };
    };
  };
  systemd.network.networks."10-wifi" = {
    matchConfig = { PermanentMACAddress = "a8:7e:ea:ed:dd:a2"; };
    DHCP = "yes";
    dhcpV6Config.UseDelegatedPrefix = false;
    domains = [ "~h.rvf6.com" ];
  };

  home-manager.users.rvfg = import ./home.nix;

  services.clash.enable = true;
  services.clash.configFile = config.sops.secrets.clash.path;
}
