{ config, ... }:
let
  directMark = 1;
in
{
  nixpkgs.overlays = [
    (self: super: {
      wpa_supplicant = super.wpa_supplicant.overrideAttrs (oldAttrs: {
        extraConfig = oldAttrs.extraConfig + ''
          CONFIG_SUITEB=y
          CONFIG_SUITEB192=y
        '';
      });
    })
  ];

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
    "pki/ca".mode = "0444";
    "pki/ybk" = { };
    "pki/xiaoxin-bundle" = { };
    "pki/xiaoxin-key" = { };
    "pki/xiaoxin-pkcs8-key" = { };
    "syncthing/cert".owner = config.services.syncthing.user;
    "syncthing/key".owner = config.services.syncthing.user;
    "wireless" = { };
  };

  presets.refind = {
    signKey = config.sops.secrets."sbsign-key".path;
    signCert = config.sops.secrets."sbsign-cert".path;
  };

  networking = {
    hostName = "xiaoxin";
    wireless = {
      enable = true;
      userControlled = {
        enable = true;
        group = "rvfg";
      };
      environmentFile = config.sops.secrets."wireless".path;
      networks = {
        rvfg = {
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
        "Xiaomi_3304_5G".psk = "@PSK_3304@";
        eduroam = {
          authProtocols = [ "WPA-EAP" "WPA-EAP-SUITE-B-192" "FT-EAP" "FT-EAP-SHA384" ];
          auth = ''
            eap=PEAP
            identity="@EDUROAM_ID@"
            password="@EDUROAM_PWD@"
          '';
        };
      };
    };
  };
  systemd.network.networks."99-wireless-client-dhcp" = {
    linkConfig.RequiredForOnline = true;
    routingPolicyRules = [
      {
        routingPolicyRuleConfig = {
          Family = "both";
          FirewallMark = directMark;
          Priority = 9;
        };
      }
    ];
    # domains = [ "~h.rvf6.com" ];
  };

  home-manager.users.rvfg = import ./home.nix;

  services.clash.enable = true;
  services.clash.configFile = config.sops.secrets.clash.path;
}
