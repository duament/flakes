{ config, ... }:
{
  presets.workstation.enable = true;

  sops.defaultSopsFile = ./secrets.yaml;
  sops.secrets = {
    "sbsign-key" = { };
    "sbsign-cert" = { };
    wireguard_key.owner = "systemd-network";
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

  home-manager.users.rvfg = import ./home.nix;
}
