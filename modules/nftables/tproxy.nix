{ lib, config, inputs, ... }:
with lib;
let
  cfg = config.networking.nftables;

  comment_filter = line: builtins.match "^[ \t]*(#.*)?$" line == null;
  china_ipv4_raw = builtins.readFile "${inputs.chnroutes2.outPath}/chnroutes.txt";
  china_ipv4_lines = builtins.filter comment_filter (splitString "\n" china_ipv4_raw);
  china_ipv4 = builtins.concatStringsSep ",\n" china_ipv4_lines;
  china_ipv6_raw = builtins.readFile "${inputs.china-operator-ip.outPath}/china6.txt";
  china_ipv6_lines = builtins.filter comment_filter (splitString "\n" china_ipv6_raw);
  china_ipv6 = builtins.concatStringsSep ",\n" china_ipv6_lines;
in {
  imports = [
    ../shadowsocks
    ../smartdns.nix
  ];

  options = {
    networking.nftables.tproxy.enable = mkOption {
      type = types.bool;
      default = false;
    };

    networking.nftables.tproxy.enableLocal = mkOption {
      type = types.bool;
      default = false;
    };

    networking.nftables.tproxy.mask = mkOption {
      type = types.int;
      default = 1;
    };

    networking.nftables.tproxy.mark = mkOption {
      type = types.int;
      default = 1;
    };

    networking.nftables.tproxy.bypassMask = mkOption {
      type = types.int;
      default = 2;
    };

    networking.nftables.tproxy.bypassMark = mkOption {
      type = types.int;
      default = 2;
    };

    networking.nftables.tproxy.port = mkOption {
      type = types.port;
      default = 1090;
    };

    networking.nftables.tproxy.dnsPort = mkOption {
      type = types.port;
      default = 1053;
    };

    networking.nftables.tproxy.src = mkOption {
      type = types.lines;
      default = "";
      example = ''
        ip saddr 10.0.0.0/24 return;
        ether saddr AA:AA:AA:AA:AA:AA return;
      '';
    };

    networking.nftables.tproxy.dst = mkOption {
      type = types.lines;
      default = "";
    };

    networking.nftables.tproxy.dnsRedirect = mkOption {
      type = types.lines;
      default = "";
    };

    networking.nftables.tproxy.all.enable = mkOption {
      type = types.bool;
      default = false;
    };

    networking.nftables.tproxy.all.port = mkOption {
      type = types.port;
      default = 1090;
    };

    networking.nftables.tproxy.all.dnsPort = mkOption {
      type = types.port;
      default = 1053;
    };

    networking.nftables.tproxy.all.src = mkOption {
      type = types.lines;
      default = "";
    };
  };

  config = mkIf cfg.tproxy.enable {
    systemd.network.networks."20-lo" = {
      enable = true;
      name = "lo";
      networkConfig = { KeepConfiguration = "static"; };
      routingPolicyRules = [
        {
          routingPolicyRuleConfig = {
            FirewallMark = cfg.tproxy.mark;
            Table = 200;
            Family = "both";
          };
        }
      ];
      routes = [
        {
          routeConfig = {
            Source = "0.0.0.0/0";
            Scope = "host";
            Table = 200;
            Type = "local";
          };
        }
        {
          routeConfig = {
            Source = "::/0";
            Table = 200;
            Type = "local";
          };
        }
      ];
    };

    networking.nftables.inputAccept = "mark and ${toString cfg.tproxy.mask} == ${toString cfg.tproxy.mark} accept";

    networking.nftables.tproxy.src = mkIf cfg.tproxy.enableLocal "fib saddr type local return";

    networking.nftables.ruleset = ''
      table inet tproxy_table {
        set special_ipv4 {
          type ipv4_addr
          flags interval
          elements = {
            0.0.0.0/8,
            10.0.0.0/8,
            100.64.0.0/10,
            127.0.0.0/8,
            169.254.0.0/16,
            172.16.0.0/12,
            192.0.0.0/24,
            192.0.2.0/24,
            192.31.196.0/24,
            192.52.193.0/24,
            192.88.99.0/24,
            192.168.0.0/16,
            192.175.48.0/24,
            198.18.0.0/15,
            198.51.100.0/24,
            203.0.113.0/24,
            224.0.0.0/4,
            240.0.0.0-255.255.255.255
          }
        }

        set special_ipv6 {
          type ipv6_addr
          flags interval
          elements = {
            ::,
            ::1,
            ::ffff:0.0.0.0/96,
            64:ff9b:1::/48,
            100::/64,
            2001::/23,
            fc00::/7,
            fe80::/10
          }
        }

        set china_ipv4 {
          type ipv4_addr
          flags interval
          elements = {
            ${china_ipv4}
          }
        }

        set china_ipv6 {
          type ipv6_addr
          flags interval
          elements = {
            ${china_ipv6}
          }
        }


        chain tproxy_src {
          mark and ${toString cfg.tproxy.bypassMask} == ${toString cfg.tproxy.bypassMark} accept;
          ${cfg.tproxy.src}
          accept;
        }

        chain tproxy_dst {
          fib daddr type local accept;
          ip daddr @special_ipv4 accept;
          ip6 daddr @special_ipv6 accept;
          ip daddr @china_ipv4 accept;
          ip6 daddr @china_ipv6 accept;
          ${cfg.tproxy.dst}
        }

        chain tproxy_dns_redirect {
          type nat hook prerouting priority dstnat; policy accept;
          jump tproxy_src;
          fib daddr type local meta l4proto { tcp, udp } th dport 53 counter redirect to :${toString cfg.tproxy.dnsPort};
          ${cfg.tproxy.dnsRedirect}
        }

        chain tproxy_chain {
          type filter hook prerouting priority mangle; policy accept;
          jump tproxy_src;
          jump tproxy_dst;
          meta l4proto { tcp, udp } tproxy to :${toString cfg.tproxy.port} mark set mark or ${toString cfg.tproxy.mark};
        }


        ${optionalString cfg.tproxy.enableLocal ''
        chain tproxy_local_dns_redirect {
          type nat hook output priority mangle; policy accept;
          mark and ${toString cfg.tproxy.bypassMask} == ${toString cfg.tproxy.bypassMark} accept;
          fib daddr type local meta l4proto { tcp, udp } th dport 53 counter redirect to :${toString cfg.tproxy.dnsPort};
        }

        chain tproxy_local_reroute {
          type route hook output priority mangle; policy accept;
          ct mark and ${toString cfg.tproxy.mask} == ${toString cfg.tproxy.mark} mark set mark or ${toString cfg.tproxy.mark};
          ct state != new accept;
          mark and ${toString cfg.tproxy.bypassMask} == ${toString cfg.tproxy.bypassMark} accept;
          jump tproxy_dst;
          meta l4proto { tcp, udp } mark set mark or ${toString cfg.tproxy.mark} ct mark set ct mark or ${toString cfg.tproxy.mark};
        }
        ''}


        ${optionalString cfg.tproxy.all.enable ''
        chain tproxy_all_src {
          ${cfg.tproxy.all.src}
          accept;
        }

        chain tproxy_all_dst {
          fib daddr type local accept;
          ip daddr @special_ipv4 accept;
          ip6 daddr @special_ipv6 accept;
        }

        chain tproxy_all_dns_redirect {
          type nat hook prerouting priority dstnat; policy accept;
          jump tproxy_all_src;
          fib daddr type local meta l4proto { tcp, udp } th dport 53 counter redirect to :${toString cfg.tproxy.all.dnsPort};
        }

        chain tproxy_all_chain {
          type filter hook prerouting priority mangle; policy accept;
          jump tproxy_all_src;
          jump tproxy_all_dst;
          meta l4proto { tcp, udp } tproxy to :${toString cfg.tproxy.all.port} mark set mark or ${toString cfg.tproxy.mark};
        }
        ''}
      }
    '';
  };
}
