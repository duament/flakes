{ config, inputs, lib, ... }:
with lib;
let
  cfg = config.networking.nftables.markChinaIP;
  nftChinaIP = import ../../lib/nft-china-ip.nix { inherit lib inputs; };
in {
  options = {
    networking.nftables.markChinaIP.enable = mkOption {
      type = types.bool;
      default = false;
    };

    networking.nftables.markChinaIP.mark = mkOption {
      type = types.int;
      default = 1;
    };

    networking.nftables.markChinaIP.extraRules = mkOption {
      type = types.lines;
      default = "";
    };
  };

  config = mkIf cfg.enable {
    networking.nftables.ruleset = ''
      table inet mark_china_ip {
        ${nftChinaIP}

        chain do_mark {
          fib daddr type local accept
          ip daddr @special_ipv4 accept
          ip6 daddr @special_ipv6 accept
          ip daddr @china_ipv4 accept
          ip6 daddr @china_ipv6 accept
          ${cfg.extraRules}
          mark 0 mark set ${builtins.toString cfg.mark}
        }

        chain pre {
          type filter hook prerouting priority -400;
          goto do_mark
        }

        chain out {
          type route hook output priority -400;
          goto do_mark
        }
      }
    '';
  };
}
