{ config, lib, pkgs, ... }:
let
  host = "or2";
  wg0 = import ../../lib/wg0.nix;
in
{
  presets.nogui.enable = true;

  sops.defaultSopsFile = ./secrets.yaml;
  sops.secrets = {
    "wireguard_key".owner = "systemd-network";
  };

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.tmpOnTmpfs = false;

  networking.hostName = host;
  networking.firewall = {
    allowedTCPPorts = [
      80
      443
    ];
    allowedUDPPorts = [
      wg0.peers.${host}.endpointPort
    ];
  };

  systemd.network.netdevs."25-wg0" = {
    enable = true;
    netdevConfig = {
      Name = "wg0";
      Kind = "wireguard";
      MTUBytes = "1340";
    };
    wireguardConfig = {
      PrivateKeyFile = config.sops.secrets.wireguard_key.path;
      ListenPort = wg0.peers.${host}.endpointPort;
    };
    wireguardPeers = [{
      wireguardPeerConfig = {
        AllowedIPs = [ "0.0.0.0/0" "::/0" ];
        PublicKey = wg0.pubkey;
      };
    }];
  };
  systemd.network.networks."25-wg0" = {
    enable = true;
    name = "wg0";
    address = [ "${wg0.peers.${host}.ipv4}/24" "${wg0.peers.${host}.ipv6}/120" ];
  };

  home-manager.users.rvfg = import ./home.nix;

  security.acme.acceptTerms = true;
  security.acme.defaults.email = "le@rvf6.com";
  services.nginx =
    let
      hstsConfig = "add_header Strict-Transport-Security \"max-age=63072000; includeSubDomains; preload\" always;";
    in
    {
      enable = true;
      package = pkgs.nginxMainline;
      recommendedGzipSettings = true;
      recommendedOptimisation = true;
      recommendedProxySettings = true;
      recommendedTlsSettings = true;
      virtualHosts = {
        "${host}.rvf6.com" = {
          forceSSL = true;
          enableACME = true;
          extraConfig = hstsConfig;
          default = true;
        };
      };
    };
}
