{ config, pkgs, ... }:
let
  host = "xiaoxin";
in
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
  };

  boot.loader.efi.efiSysMountPoint = "/efi";

  presets.refind = {
    signKey = config.sops.secrets."sbsign-key".path;
    signCert = config.sops.secrets."sbsign-cert".path;
    configurationLimit = 3;
  };

  networking = {
    hostName = host;
    useDHCP = false;
    useNetworkd = true;
    wireless = {
      enable = true;
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
  };

  security.pam.services.swaylock = { };
  hardware.opengl.enable = true;
  xdg.portal.wlr.enable = true;
  services.greetd = {
    enable = true;
    settings = {
      default_session.command = "${pkgs.greetd.tuigreet}/bin/tuigreet --cmd ${pkgs.writeShellScript "sway" ''
        systemctl --user import-environment
        exec systemctl --wait --user start sway.service
      ''}";
    };
  };
  systemd.services.greetd.serviceConfig.ExecStartPre = "/run/current-system/systemd/bin/systemctl restart systemd-vconsole-setup";

  home-manager.users.rvfg = import ./home.nix;

  services.clash.enable = true;
  services.clash.configFile = config.sops.secrets.clash.path;
}
