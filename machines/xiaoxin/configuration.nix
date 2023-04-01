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
    domains = [ "~h.rvf6.com" ];
  };

  security.pam.services.swaylock = { };
  hardware.opengl.enable = true;
  xdg.portal.wlr.enable = true;
  services.greetd = {
    enable = true;
    settings =
      let
        sway-script = pkgs.writeShellScript "sway" ''
          systemctl --user import-environment PATH SSH_AUTH_SOCK XDG_SEAT XDG_SESSION_CLASS XDG_SESSION_ID
          exec systemctl --wait --user start sway.service
        '';
      in
      {
        initial_session = {
          user = "rvfg";
          command = sway-script;
        };
        default_session = {
          command = "${pkgs.greetd.tuigreet}/bin/tuigreet --cmd ${sway-script}";
        };
      };
  };
  home-manager.users.rvfg = import ./home.nix;

  environment.persistence."/persist".users.rvfg = {
    directories = [
      ".gnupg"
      ".mozilla"
    ];
  };

  services.clash.enable = true;
  services.clash.configFile = config.sops.secrets.clash.path;
}
