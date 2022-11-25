{ lib, config, inputs, pkgs, ... }:
with lib;
let
  cfg = config.networking.warp;
in
{
  options = {
    networking.warp.enable = mkOption {
      type = types.bool;
      default = false;
    };

    networking.warp.endpointAddr = mkOption {
      type = types.str;
      default = "162.159.192.9";
    };

    networking.warp.endpointPort = mkOption {
      type = types.port;
      default = 4500;
    };

    networking.warp.endpoint = mkOption {
      type = types.str;
      default = "${cfg.endpointAddr}:${builtins.toString cfg.endpointPort}";
    };

    networking.warp.mtu = mkOption {
      type = types.int;
      default = 1420;
    };

    networking.warp.mark = mkOption {
      type = types.int;
      default = 1;
    };

    networking.warp.routeMark = mkOption {
      type = types.int;
      default = 2;
    };
    networking.warp.routingId = mkOption {
      type = types.str;
      default = "0x0";
    };

    networking.warp.keyFile = mkOption {
      type = types.str;
      default = config.sops.secrets.warp_key.path;
    };

    networking.warp.pubkey = mkOption {
      type = types.str;
      default = "bmXOC+F1FxEMF9dyiK2H5/1SUtzH0JuVo51h2wPfgyo=";
    };

    networking.warp.address = mkOption {
      type = types.listOf types.str;
      default = [ ];
    };

    networking.warp.table = mkOption {
      type = types.int;
      default = 1;
    };

    networking.warp.extraMarkRules = mkOption {
      type = types.lines;
      default = "";
    };
  };

  config = mkIf cfg.enable {
    services.resolved.enable = false;
    environment.etc."resolv.conf".text = "nameserver 127.0.0.1";

    services.smartdns.enable = true;
    services.smartdns.nonChinaDns = [ "1.1.1.1" ];

    networking.nftables.markChinaIP = {
      enable = true;
      mark = cfg.routeMark;
      extraRules = cfg.extraMarkRules;
    };
    networking.nftables.ruleset = ''
      table inet warp {
        chain out {
          type filter hook output priority mangle;
          ip daddr ${cfg.endpointAddr} udp dport ${builtins.toString cfg.endpointPort} @th,72,24 set ${cfg.routingId}
        }

        chain in {
          type filter hook input priority mangle;
          ip saddr ${cfg.endpointAddr} udp sport ${builtins.toString cfg.endpointPort} @th,72,24 set 0x0
        }

        chain masq {
          type nat hook postrouting priority srcnat;
          oifname warp masquerade
        }
      }
    '';

    systemd.network.netdevs."25-warp" = {
      netdevConfig = {
        Name = "warp";
        Kind = "wireguard";
        MTUBytes = toString cfg.mtu;
      };
      wireguardConfig = {
        PrivateKeyFile = cfg.keyFile;
        FirewallMark = cfg.mark;
        RouteTable = cfg.table;
      };
      wireguardPeers = [
        {
          wireguardPeerConfig = {
            AllowedIPs = [ "0.0.0.0/0" "::/0" ];
            Endpoint = cfg.endpoint;
            PersistentKeepalive = 25;
            PublicKey = cfg.pubkey;
          };
        }
      ];
    };
    systemd.network.networks."25-warp" = {
      name = "warp";
      address = cfg.address;
      routingPolicyRules = [
        {
          routingPolicyRuleConfig = {
            FirewallMark = cfg.routeMark;
            Table = cfg.table;
            Priority = 10;
            Family = "both";
          };
        }
      ];
    };
  };
}
