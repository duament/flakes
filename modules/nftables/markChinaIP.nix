{ config, inputs, lib, ... }:
with lib;
let
  cfg = config.networking.nftables.markChinaIP;
  nftChinaIP = import ../../lib/nft-china-ip.nix { inherit lib inputs; };
in
{
  options = {
    networking.nftables.markChinaIP.enable = mkOption {
      type = types.bool;
      default = false;
    };

    networking.nftables.markChinaIP.mark = mkOption {
      type = types.int;
      default = 1;
    };

    networking.nftables.markChinaIP.extraIPv4Rules = mkOption {
      type = types.lines;
      default = "";
    };

    networking.nftables.markChinaIP.extraIPv6Rules = mkOption {
      type = types.lines;
      default = "";
    };
  };

  config = mkIf cfg.enable {
    networking.nftables.stopRuleset = ''
      table ip mark-china-ip
      delete table ip mark-china-ip

      table ip6 mark-china-ip
      delete table ip6 mark-china-ip
    '';

    networking.nftables.ruleset = ''
      table ip mark-china-ip {
        ${nftChinaIP.ipv4}

        chain do-mark {
          fib daddr type local accept
          ip daddr @special-ipv4 accept
          ip daddr @china-ipv4 accept
          ${cfg.extraIPv4Rules}
          mark 0 mark set ${builtins.toString cfg.mark}
        }

        chain pre {
          type filter hook prerouting priority -400;
          goto do-mark
        }

        chain out {
          type route hook output priority -400;
          goto do-mark
        }
      }

      table ip6 mark-china-ip {
        ${nftChinaIP.ipv6}

        chain do-mark {
          fib daddr type local accept
          ip6 daddr @special-ipv6 accept
          ip6 daddr @china-ipv6 accept
          ${cfg.extraIPv6Rules}
          mark 0 mark set ${builtins.toString cfg.mark}
        }

        chain pre {
          type filter hook prerouting priority -400;
          goto do-mark
        }

        chain out {
          type route hook output priority -400;
          goto do-mark
        }
      }
    '';
  };
}
