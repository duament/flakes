{ config, lib, ... }:
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
    "pki/ca" = { };
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
    wireless = {
      enable = true;
      userControlled = {
        enable = true;
        group = "rvfg";
      };
      networks.rvfg = {
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
  };
  systemd.network.networks."99-wireless-client-dhcp".linkConfig.RequiredForOnline = true;

  presets.wireguard.wg0.enable = lib.mkForce false;
  system.activationScripts.strongswan-swanctl-private = lib.stringAfter [ "etc" ] ''
    mkdir -p /etc/swanctl/private
    ln -sf ${config.sops.secrets."pki/${config.networking.hostName}-pkcs8-key".path} /etc/swanctl/private/${config.networking.hostName}.key
  '';
  services.strongswan-swanctl = {
    enable = true;
    swanctl.connections.t430 = {
      local.${config.networking.hostName} = {
        auth = "pubkey";
        id = "${config.networking.hostName}@rvf6.com";
        certs = [ config.sops.secrets."pki/${config.networking.hostName}-bundle".path ];
      };
      remote.t430 = {
        auth = "pubkey";
        id = "t430.rvf6.com";
        cacerts = [ config.sops.secrets."pki/ca".path config.sops.secrets."pki/ybk".path ];
      };
      children.t430 = {
        local_ts = [ "0.0.0.0/0" "::/0" ];
        remote_ts = [ "0.0.0.0/0" "::/0" ];
        # start_action = "trap";
        start_action = "start";
        dpd_action = "restart";
      };
      remote_addrs = [ "h.rvf6.com" ];
      version = 2;
      vips = [ "0.0.0.0" "::" ];
      proposals = [ "aes256gcm16-prfsha384-curve25519" "aes256gcm16-prfsha384-ecp384" ];
    };
    strongswan.extraConfig = ''
      charon {
        plugins {
          resolve {
            resolvconf {
              iface = wlp1s0
              path = ${config.networking.resolvconf.package}/bin/resolvconf
            }
          }
        }
      }
    '';
  };
  systemd.services.strongswan-swanctl.after = [ "systemd-networkd-wait-online.service" ];

  home-manager.users.rvfg = import ./home.nix;

  services.clash.enable = true;
  services.clash.configFile = config.sops.secrets.clash.path;
}
