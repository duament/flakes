{ config, lib, pkgs, self, ... }:
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
    "syncthing/cert".owner = config.services.syncthing.user;
    "syncthing/key".owner = config.services.syncthing.user;
  };

  presets.refind = {
    signKey = config.sops.secrets."sbsign-key".path;
    signCert = config.sops.secrets."sbsign-cert".path;
    configurationLimit = 3;
  };

  networking = {
    hostName = "xiaoxin";
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
    dhcpV6Config.UseDelegatedPrefix = false;
    domains = [ "~h.rvf6.com" ];
  };

  programs.hyprland.enable = true;
  security.pam.services.swaylock = { };
  hardware.opengl.enable = true;
  #xdg.portal.wlr.enable = true;
  services.greetd = {
    enable = true;
    settings =
      let
        sway-script = pkgs.writeShellScript "sway" ''
          systemctl --user import-environment PATH SSH_AUTH_SOCK NIX_USER_PROFILE_DIR NIX_PROFILES XDG_SEAT XDG_SESSION_CLASS XDG_SESSION_ID
          exec systemctl --wait --user start sway.service
        '';
        hyprland-script = pkgs.writeShellScript "sway" ''
          systemctl --user import-environment PATH SSH_AUTH_SOCK NIX_USER_PROFILE_DIR NIX_PROFILES XDG_SEAT XDG_SESSION_CLASS XDG_SESSION_ID
          exec systemctl --wait --user start hyprland.service
        '';
      in
      {
        initial_session = {
          user = "rvfg";
          command = hyprland-script;
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
      ".thunderbird"
    ];
  };

  services.clash.enable = true;
  services.clash.configFile = config.sops.secrets.clash.path;

  services.syncthing = {
    enable = true;
    openDefaultPorts = true;
    cert = config.sops.secrets."syncthing/cert".path;
    key = config.sops.secrets."syncthing/key".path;
    devices = self.data.syncthing.devices;
    folders = lib.getAttrs [ "keepass" "notes" "session" ] self.data.syncthing.folders;
  };
  systemd.tmpfiles.rules = [ "d ${config.services.syncthing.dataDir} 2770 syncthing syncthing" "a ${config.services.syncthing.dataDir} - - - - d:g::rwx" ];
  users.users.rvfg.extraGroups = [ "syncthing" ];
}
