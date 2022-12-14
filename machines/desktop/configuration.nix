{ config, pkgs, ... }:
let
  host = "desktop";
  mark = 2;
in
{
  presets.workstation.enable = true;

  sops.defaultSopsFile = ./secrets.yaml;
  sops.secrets = {
    "sbsign-key" = { };
    "sbsign-cert" = { };
    clash = {
      format = "binary";
      sopsFile = ../../lib/clash.secrets;
    };
    wireguard_key.owner = "systemd-network";
  };

  presets.refind = {
    signKey = config.sops.secrets."sbsign-key".path;
    signCert = config.sops.secrets."sbsign-cert".path;
    configurationLimit = 10;
  };

  networking.hostName = host;
  networking.useDHCP = false;
  networking.networkmanager = {
    enable = true;
    unmanaged = [ "wg0" ];
    dns = "systemd-resolved";
  };
  networking.nftables.masquerade = [ "oifname \"wg0\"" ];
  networking.nftables.markChinaIP = {
    enable = true;
    mark = mark;
  };
  systemd.network =
    let
      wg0 = import ../../lib/wg0.nix;
      wgTable = 10;
      wgMark = 1;
    in
    {
      enable = true;
      netdevs."25-wg0" = {
        netdevConfig = {
          Name = "wg0";
          Kind = "wireguard";
        };
        wireguardConfig = {
          PrivateKeyFile = config.sops.secrets.wireguard_key.path;
          FirewallMark = wgMark;
          RouteTable = wgTable;
        };
        wireguardPeers = [
          {
            wireguardPeerConfig = {
              AllowedIPs = [ "0.0.0.0/0" "::/0" ];
              Endpoint = wg0.endpoint;
              PublicKey = wg0.pubkey;
            };
          }
        ];
      };
      networks."25-wg0" = {
        name = "wg0";
        address = [ "${wg0.peers.${host}.ipv4}/24" "${wg0.peers.${host}.ipv6}/120" ];
        dns = [ wg0.gateway6 ];
        domains = [ "~." ];
        routingPolicyRules = [
          {
            routingPolicyRuleConfig = {
              Family = "both";
              FirewallMark = wgMark;
              Priority = 9;
            };
          }
          {
            routingPolicyRuleConfig = {
              Family = "both";
              FirewallMark = mark;
              Table = wgTable;
              Priority = 10;
            };
          }
        ];
      };
    };

  home-manager.users.rvfg = import ./home.nix;

  systemd.tmpfiles.rules = [ "L+ /run/gdm/.config/monitors.xml - - - - ${./monitors.xml}" ];

  services.clash.enable = true;
  services.clash.configFile = config.sops.secrets.clash.path;
}
