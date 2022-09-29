{ lib, config, inputs, ... }:
with lib;
let
  cfg = config.networking.nftables;
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

    networking.nftables.tproxy.server = mkOption {
      type = types.str;
      default = "tw1";
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
      default = config.services.smartdns.bindPort;
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

    networking.nftables.tproxy.all.enable = mkOption {
      type = types.bool;
      default = false;
    };

    networking.nftables.tproxy.all.server = mkOption {
      type = types.str;
      default = "tw1";
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

    services.smartdns = {
      enable = true;
      bindPort = mkDefault 1053;
      nonChinaDns = [
        "127.0.0.1:${builtins.toString config.services.shadowsocks.tunnel.googleDNS.port}"
        "127.0.0.1:${builtins.toString config.services.shadowsocks.tunnel.cfDNS.port}"
      ];
      settings.server-tcp = config.services.smartdns.nonChinaDns;
    };

    networking.nftables.inputAccept = "mark and ${toString cfg.tproxy.mask} == ${toString cfg.tproxy.mark} accept";

    networking.nftables.tproxy.src = mkIf cfg.tproxy.enableLocal "fib saddr type local return";

    networking.nftables.ruleset = ''
      table inet tproxy_table {
        ${import ../../lib/nft-china-ip.nix { inherit lib inputs; }}

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
