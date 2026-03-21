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

  systemd.network.links."50-enxe89c2597d186" = {
    matchConfig.MACAddress = "e8:9c:25:97:d1:86";
    linkConfig = {
      NamePolicy = [
        "keep"
        "kernel"
        "database"
        "onboard"
        "slot"
        "path"
      ];
      AlternativeNamesPolicy = [
        "database"
        "onboard"
        "slot"
        "path"
        "mac"
      ];
      MACAddressPolicy = "persistent";
      WakeOnLan = "magic";
    };
  };

  presets.wireguard.wg0 = {
    enable = true;
    clientPeers.router = {
      endpoint = "10.8.0.1:11111";
    };
  };

  services.pipewire.wireplumber.extraConfig."90-disable-suspension" = {
    "monitor.alsa.rules" = [
      {
        matches = [
          {
            # Matches all sources
            "node.name" = "~alsa_input.*";
          }
          {
            # Matches all sinks
            "node.name" = "~alsa_output.*";
          }
        ];
        actions = {
          update-props = {
            "session.suspend-timeout-seconds" = 0;
          };
        };
      }
    ];
  };

  home-manager.users.rvfg = import ./home.nix;
}
