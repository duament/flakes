{ config, lib, ... }:
let
  inherit (lib) mkForce;
in
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
    "pki/bundle" = { };
    "pki/pkcs8-key" = { };
    "syncthing/cert".owner = config.services.syncthing.user;
    "syncthing/key".owner = config.services.syncthing.user;
  };

  presets.refind = {
    signKey = config.sops.secrets."sbsign-key".path;
    signCert = config.sops.secrets."sbsign-cert".path;
  };

  networking = {
    hostName = "desktop";
    wireless.networks.rvfg = {
      authProtocols = [
        "WPA-EAP-SUITE-B-192"
        "FT-EAP"
        "FT-EAP-SHA384"
      ];
      auth = ''
        eap=TLS
        pairwise=GCMP-256
        group=GCMP-256
        identity="desktop@rvf6.com"
        ca_cert="${config.sops.secrets."pki/ca".path}"
        client_cert="${config.sops.secrets."pki/bundle".path}"
        private_key="${config.sops.secrets."pki/pkcs8-key".path}"
      '';
    };
  };
  systemd.services.wpa_supplicant.wantedBy = mkForce [ ];

  presets.wireguard.wg0 = {
    enable = true;
    clientPeers.router = {
      endpoint = "10.8.0.1:11111";
    };
  };

  #presets.uutunnel.enable = true;
  #networking.warp = {
  #  enable = true;
  #  #endpointAddr = "162.159.192.1";
  #  endpointAddr = "127.0.0.1";
  #  endpointPort = 20000;
  #  mtu = 1380;
  #  mark = 3;
  #  routingId = "0x616add";
  #  keyFile = config.sops.secrets.warp_key.path;
  #  address = [
  #    "172.16.0.2/32"
  #    "2606:4700:110:8395:570b:d0c1:ea2a:8251/128"
  #  ];
  #  table = 20;
  #};
  #presets.wireguard.keepAlive.interfaces = [ "warp" ];
  #networking.nftables.markChinaIP = {
  #  enable = true;
  #  mark = 2;
  #};
  #systemd.network.networks."25-warp".routingPolicyRules = [
  #  {
  #    FirewallMark = 2;
  #    Table = 20;
  #    Priority = 20;
  #    Family = "both";
  #  }
  #];

  home-manager.users.rvfg = import ./home.nix;
}
