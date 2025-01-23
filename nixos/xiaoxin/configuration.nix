{ config, self, ... }:
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
    wireless.enable = false;
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
        identity="xiaoxin@rvf6.com"
        ca_cert="${config.sops.secrets."pki/ca".path}"
        client_cert="${config.sops.secrets."pki/xiaoxin-bundle".path}"
        private_key="${config.sops.secrets."pki/xiaoxin-key".path}"
      '';
    };
    networkmanager = {
      unmanaged = [ "except:type:wifi" ];
      ensureProfiles.profiles.rvfg = {
        connection = {
          id = "rvfg";
          uuid = "2ebf7581-f536-483e-b553-f7b67727e8f8";
          type = "wifi";
          autoconnect = true;
          permissions = "user:rvfg:;";
        };
        wifi = {
          mode = "infrastructure";
          ssid = "rvfg";
        };
        wifi-security = {
          key-mgmt = "wpa-eap-suite-b-192";
          pmf = "3";
        };
        "802-1x" = {
          ca-cert = "/run/credentials/NetworkManager.service/ca";
          client-cert = "/run/credentials/NetworkManager.service/bundle";
          eap = "tls;";
          identity = "xiaoxin@rvf6.com";
          private-key = "/run/credentials/NetworkManager.service/key";
        };
        ipv4 = {
          method = "auto";
        };
        ipv6 = {
          addr-gen-mode = "stable-privacy";
          method = "auto";
        };
      };
    };
  };
  systemd.services.NetworkManager.serviceConfig.LoadCredential = [
    "ca:${config.sops.secrets."pki/ca".path}"
    "bundle:${config.sops.secrets."pki/xiaoxin-bundle".path}"
    "key:${config.sops.secrets."pki/xiaoxin-key".path}"
  ];

  presets.wireguard.wg0 = {
    enable = true;
    clientPeers.router = {
      endpoint = "10.8.0.1:11111";
    };
  };
  presets.wireguard.reResolve.wg-router = {
    address = "t430-rvfg.duckdns.org";
    pubkey = self.data.wg0.peers.router.pubkey;
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
    address = [
      "172.16.0.2/32"
      "2606:4700:110:8174:c34d:c0f9:7367:dd59/128"
    ];
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
      Priority = 16384;
      Family = "both";
    }
  ];
  presets.smartdns.enable = true;

  home-manager.users.rvfg = import ./home.nix;
}
