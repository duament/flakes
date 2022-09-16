{ lib, config, inputs, pkgs, ... }:
with lib;
let
  cfg = config.networking.warp;

  comment_filter = line: builtins.match "^[ \t]*(#.*)?$" line == null;
  china_ipv4_raw = builtins.readFile "${inputs.chn-cidr-list.outPath}/ipv4.txt";
  china_ipv4 = builtins.filter comment_filter (splitString "\n" china_ipv4_raw);
  china_ipv6_raw = builtins.readFile "${inputs.chn-cidr-list.outPath}/ipv6.txt";
  china_ipv6 = builtins.filter comment_filter (splitString "\n" china_ipv6_raw);

  special_ipv4 = [
    "10.0.0.0/8"
    "100.64.0.0/10"
    "169.254.0.0/16"
    "172.16.0.0/12"
    "192.0.0.0/24"
    "192.0.2.0/24"
    "192.31.196.0/24"
    "192.52.193.0/24"
    "192.88.99.0/24"
    "192.168.0.0/16"
    "192.175.48.0/24"
    "198.18.0.0/15"
    "198.51.100.0/24"
    "203.0.113.0/24"
    "224.0.0.0/4"
    "240.0.0.0/4"
  ];

  special_ipv6 = [
    "::ffff:0.0.0.0/96"
    "64:ff9b:1::/48"
    "100::/64"
    "2001::/23"
    "fc00::/7"
    "fe80::/10"
  ];

  generateRule = ip: {
    routingPolicyRuleConfig = {
      To = ip;
      Priority = 9;
    };
  };
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
        chain out {
          type filter hook output priority mangle;
          ip daddr ${cfg.endpointAddr} udp dport ${builtins.toString cfg.endpointPort} @th,72,24 set ${cfg.routingId};
        }

        chain in {
          type filter hook input priority mangle;
          ip saddr ${cfg.endpointAddr} udp sport ${builtins.toString cfg.endpointPort} @th,72,24 set 0x0;
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
      networkConfig = { IPMasquerade = "both"; };
      routingPolicyRules = [
        {
          routingPolicyRuleConfig = {
            FirewallMark = cfg.mark;
            InvertRule = true;
            Table = cfg.table;
            Priority = 10;
            Family = "both";
          };
        }
      ] ++ (map generateRule special_ipv4)
        ++ (map generateRule special_ipv6);
    };
    systemd.services."warp-setup-china-routes" = {
      after = [ "network-online.target" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
      };
      path = [ pkgs.iproute2 pkgs.jq ];
      script = ''
        gateway4=$(ip --json route | jq -r '[.[] | select(.dst=="default")][0] | .gateway')
        dev4=$(ip --json route | jq -r '[.[] | select(.dst=="default")][0] | .dev')
        gateway6=$(ip -6 --json route | jq -r '[.[] | select(.dst=="default")][0] | .gateway')
        dev6=$(ip -6 --json route | jq -r '[.[] | select(.dst=="default")][0] | .dev')

        ${concatStringsSep "\n" (map (i: "ip route add ${i} table ${builtins.toString cfg.table} via $gateway4 dev $dev4") china_ipv4)}
        ${concatStringsSep "\n" (map (i: "ip -6 route add ${i} table ${builtins.toString cfg.table} via $gateway6 dev $dev6") china_ipv6)}
      '';
    };
  };
}
