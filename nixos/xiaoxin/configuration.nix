{ config, ... }:
{
  presets.workstation.enable = true;

  users.groups.pki = { };

  sops.defaultSopsFile = ./secrets.yaml;
  sops.secrets =
    let
      pkiConfig = {
        mode = "0440";
        group = "pki";
      };
    in
    {
      "sbsign-key" = { };
      "sbsign-cert" = { };
      wireguard_key.owner = "systemd-network";
      warp_key.owner = "systemd-network";
      "pki/ca".mode = "0444";
      "pki/ybk" = pkiConfig;
      "pki/xiaoxin-bundle" = pkiConfig;
      "pki/xiaoxin-key" = pkiConfig;
      "pki/xiaoxin-pkcs8-key" = pkiConfig;
      "syncthing/cert".owner = config.services.syncthing.user;
      "syncthing/key".owner = config.services.syncthing.user;
    };

  presets.refind = {
    signKey = config.sops.secrets."sbsign-key".path;
    signCert = config.sops.secrets."sbsign-cert".path;
  };

  networking = {
    hostName = "xiaoxin";
    wireless.enable = true;
    #wireless.networks.rvfg = {
    #  authProtocols = [
    #    "WPA-EAP-SUITE-B-192"
    #    "FT-EAP"
    #    "FT-EAP-SHA384"
    #  ];
    #  auth = ''
    #    eap=TLS
    #    pairwise=GCMP-256
    #    group=GCMP-256
    #    identity="xiaoxin@rvf6.com"
    #    ca_cert="${config.sops.secrets."pki/ca".path}"
    #    client_cert="${config.sops.secrets."pki/xiaoxin-bundle".path}"
    #    private_key="${config.sops.secrets."pki/xiaoxin-key".path}"
    #  '';
    #};
    networkmanager = {
      enable = true;
      unmanaged = [ "except:type:wifi" ];
      ensureProfiles.profiles.rvfg = {
        connection = {
          id = "rvfg";
          uuid = "2ebf7581-f536-483e-b553-f7b67727e8f8";
          type = "wifi";
          autoconnect = true;
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
          ca-cert = config.sops.secrets."pki/ca".path;
          client-cert = config.sops.secrets."pki/xiaoxin-bundle".path;
          eap = "tls";
          identity = "xiaoxin@rvf6.com";
          private-key = config.sops.secrets."pki/xiaoxin-key".path;
          # make NM happy
          private-key-password = "null";
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
  systemd.services.NetworkManager.serviceConfig.SupplementaryGroups = [ "pki" ];
  systemd.services.wpa_supplicant.serviceConfig = {
    BindReadOnlyPaths = [
      "/var/lib/nixos"
      config.sops.secrets."pki/ca".path
      config.sops.secrets."pki/xiaoxin-bundle".path
      config.sops.secrets."pki/xiaoxin-key".path
    ];
    SupplementaryGroups = [ "pki" ];
  };
  systemd.network.networks."10-wireless" = {
    matchConfig.WLANInterfaceType = "station";
    linkConfig.Unmanaged = true;
  };

  presets.wireguard.wg0 = {
    enable = true;
    clientPeers.router = {
      endpoint = "10.8.0.1:11111";
      route = null;
    };
  };
  #presets.wireguard.reResolve.wg-router = {
  #  address = "t430-rvfg.duckdns.org";
  #  pubkey = self.data.wg0.peers.router.pubkey;
  #};

  home-manager.users.rvfg = import ./home.nix;
}
