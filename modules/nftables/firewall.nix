{ lib, config, ... }:
with lib;
let
  cfg = config.networking.nftables;
in {
  options = {
    networking.nftables.inputAccept = mkOption {
      type = types.lines;
      default = "";
    };

    networking.nftables.forwardAccept = mkOption {
      type = types.lines;
      default = "";
    };

    networking.nftables.rpfilter = mkOption {
      type = types.bool;
      default = true;
    };

    networking.nftables.masquerade = mkOption {
      type = types.listOf types.str;
      default = [];
      example = [ "oifname \"extern*\"" ];
    };

    networking.nftables.mssClamping = mkOption {
      type = types.bool;
      default = false;
    };

    networking.nftables.allowPing = mkOption {
      type = types.bool;
      default = true;
    };

    networking.nftables.allowMulticast = mkOption {
      type = types.bool;
      default = false;
    };
  };

  config = mkIf cfg.enable {
    networking.nftables.ruleset = ''
      ${optionalString cfg.rpfilter ''
      table ip6 rpfilter {
        chain rpfilter {
          type filter hook prerouting priority raw; policy drop;
          fib saddr oif != 0 accept
        }
      }
      ''}

      table inet firewall {
        chain input {
          type filter hook input priority filter; policy drop;
          iif lo accept
          icmpv6 type { nd-router-solicit, nd-router-advert, nd-neighbor-solicit, nd-neighbor-advert } accept
          ${optionalString cfg.allowMulticast ''
          meta l4proto igmp accept
          ip6 saddr fe80::/10 icmpv6 type { mld-listener-query, mld-listener-report, mld-listener-reduction, mld2-listener-report } accept
          ''}
          ct state vmap { established : accept, related : accept, invalid : drop, new : jump input_accept }
          meta l4proto tcp reject with tcp reset
          reject
        }

        chain input_accept {
          ${optionalString cfg.allowPing ''
          icmp type echo-request limit rate 20/second accept
          icmpv6 type echo-request limit rate 20/second accept
          ''}
          meta nfproto ipv4 udp dport 68 accept comment "DHCP client"
          meta nfproto ipv6 udp dport 546 accept comment "DHCPv6 client"
          ${cfg.inputAccept}
        }

        chain forward {
          type filter hook forward priority filter; policy drop;
          ct state vmap { established : accept, related : accept, invalid : drop, new : jump forward_accept }
        }

        chain forward_accept {
          ${cfg.forwardAccept}
        }

        ${optionalString (length cfg.masquerade != 0) ''
        chain masq {
          type nat hook postrouting priority srcnat;
          ${concatStringsSep " masquerade\n" cfg.masquerade} masquerade
        }
        ''}

        ${optionalString cfg.mssClamping ''
        chain mss_clamping {
          type filter hook forward priority mangle;
          tcp flags syn tcp option maxseg size set rt mtu
        }
        ''}
      }
    '';
  };
}
