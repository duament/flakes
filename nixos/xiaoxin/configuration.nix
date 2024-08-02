{ config, ... }:
{
  presets.workstation.enable = true;

  sops.defaultSopsFile = ./secrets.yaml;
  sops.secrets = {
    "sbsign-key" = { };
    "sbsign-cert" = { };
    wireguard_key.owner = "systemd-network";
    warp_key.owner = "systemd-network";
    "pki/ca".mode = "0444";
    "pki/ybk" = { };
    "pki/xiaoxin-bundle" = { };
    "pki/xiaoxin-key" = { };
    "pki/xiaoxin-pkcs8-key" = { };
    "syncthing/cert".owner = config.services.syncthing.user;
    "syncthing/key".owner = config.services.syncthing.user;
  };

  presets.refind = {
    signKey = config.sops.secrets."sbsign-key".path;
    signCert = config.sops.secrets."sbsign-cert".path;
  };

  networking = {
    hostName = "xiaoxin";
    wireless.networks.rvfg = {
      authProtocols = [ "WPA-EAP-SUITE-B-192" "FT-EAP" "FT-EAP-SHA384" ];
      auth = ''
        eap=TLS
        pairwise=GCMP-256
        group=GCMP-256
        identity="xiaoxin@rvf6.com"
        ca_cert="${config.sops.secrets."pki/ca".path}"
        client_cert="${config.sops.secrets."pki/xiaoxin-bundle".path}"
        private_key="${config.sops.secrets."pki/xiaoxin-key".path}"
      '';
    };
  };

  services.uu = {
    enable = false;
    useFakeIptables = true;
  };
  presets.uutunnel.enable = true;
  networking.warp = {
    enable = true;
    #endpointAddr = "162.159.192.1";
    endpointAddr = "127.0.0.1";
    endpointPort = 20000;
    mtu = 1380;
    mark = 3;
    routingId = "0x699b5e";
    keyFile = config.sops.secrets.warp_key.path;
    address = [ "172.16.0.2/32" "2606:4700:110:8174:c34d:c0f9:7367:dd59/128" ];
    table = 20;
  };
  presets.wireguard.keepAlive.interfaces = [ "warp" ];
  networking.nftables.markChinaIP = {
    enable = true;
    mark = 2;
  };
  systemd.network.networks."25-warp".routingPolicyRules = [
    {
      FirewallMark = 2;
      Table = 20;
      Priority = 20;
      Family = "both";
    }
  ];
  presets.smartdns.enable = true;

  home-manager.users.rvfg = import ./home.nix;
}
