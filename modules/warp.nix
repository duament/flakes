{ lib, config, inputs, pkgs, ... }:
with lib;
let
  cfg = config.networking.warp;
in {
  imports = [
    ./smartdns.nix
  ];

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

    networking.warp.pubkey = mkOption {
      type = types.str;
      default = "";
    };

    networking.warp.address = mkOption {
      type = types.listOf types.str;
      default = [ ];
    };

    networking.warp.table = mkOption {
      type = types.int;
      default = 1;
    };
  };

  config = mkIf cfg.enable {
    services.resolved.enable = false;
    environment.etc."resolv.conf".text = "nameserver 127.0.0.1";

    services.smartdns.enable = true;
    services.smartdns.nonChinaDns = [ "1.1.1.1" ];

    networking.nftables.ruleset = ''
      table inet warp {
        ${import ../lib/nft-china-ip.nix { inherit lib inputs; }}

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

        chain mark_warp {
          fib daddr type local accept
          ip daddr @special_ipv4 accept
          ip6 daddr @special_ipv6 accept
          ip daddr @china_ipv4 accept
          ip6 daddr @china_ipv6 accept
          mark 0 mark set ${builtins.toString cfg.routeMark}
        }

        chain mark_warp_pre {
          type filter hook prerouting priority mangle;
          goto mark_chain
        }

        chain mark_warp_out {
          type route hook output priority mangle;
          goto mark_chain
        }
      }
    '';

    systemd.network.netdevs."25-warp" = {
      netdevConfig = { Name = "warp"; Kind = "wireguard"; };
      wireguardConfig = {
        PrivateKeyFile = config.sops.secrets.warp_key.path;
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
