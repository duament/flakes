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
  };

  config = mkIf cfg.enable {
    networking.nftables.ruleset = ''
      ${optionalString cfg.rpfilter ''
      table ip6 rpfilter {
        chain rpfilter {
          type filter hook prerouting priority -300; policy drop;
          fib saddr oif != 0 accept
        }
      }
      ''}

      table inet firewall {
        chain input {
          type filter hook input priority 0; policy drop;

          iif lo accept comment "Accept any localhost traffic"
          ct state invalid drop comment "Drop invalid connections"
          ct state established,related accept comment "Accept traffic originated from us"
          meta l4proto ipv6-icmp icmpv6 type { destination-unreachable, packet-too-big, time-exceeded, parameter-problem, mld-listener-query, mld-listener-report, mld-listener-reduction, nd-router-solicit, nd-router-advert, nd-neighbor-solicit, nd-neighbor-advert, ind-neighbor-solicit, ind-neighbor-advert, mld2-listener-report } accept comment "Accept ICMPv6"
          meta l4proto icmp icmp type { destination-unreachable, router-solicitation, router-advertisement, time-exceeded, parameter-problem } accept comment "Accept ICMP"
          meta l4proto udp ct state new jump input_accept
          meta l4proto tcp tcp flags & (fin|syn|rst|ack) == syn ct state new jump input_accept
          reject with icmpx type port-unreachable
        }

        chain input_accept {
          ${cfg.inputAccept}
        }

        chain forward {
          type filter hook forward priority 0; policy drop;

          ct state related,established accept
          jump forward_accept
          reject with icmpx type port-unreachable
        }

        chain forward_accept {
          ${cfg.forwardAccept}
        }

        ${optionalString (length cfg.masquerade != 0) ''
        chain nat_chain {
          type nat hook postrouting priority 0;
          ${concatStringsSep " masquerade\n" cfg.masquerade} masquerade
        }
        ''}

        ${optionalString cfg.mssClamping ''
        chain mss_clamping {
          type filter hook forward priority -150;
          tcp flags syn tcp option maxseg size set rt mtu
        }
        ''}
      }
    '';
  };
}
