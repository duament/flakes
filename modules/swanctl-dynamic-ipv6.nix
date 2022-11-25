{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.services.swanctlDynamicIPv6;
in
{
  options = {
    services.swanctlDynamicIPv6.enable = mkOption {
      type = types.bool;
      default = false;
    };

    services.swanctlDynamicIPv6.prefixInterface = mkOption {
      type = types.str;
      default = "eth0";
    };

    services.swanctlDynamicIPv6.suffix = mkOption {
      type = types.str;
      default = "::1";
    };

    services.swanctlDynamicIPv6.poolName = mkOption {
      type = types.str;
      default = "";
    };

    services.swanctlDynamicIPv6.extraPools = mkOption {
      type = types.lines;
      default = "";
    };
  };

  config = mkIf cfg.enable {
    systemd.services."swanctl-dynamic-ipv6" = {
      after = [ "network-online.target" ];
      path = with pkgs; [ iproute2 jq sipcalc gawk strongswan ];
      script = ''
        set -o pipefail

        get_prefix() {
          if [[ -n "$1" ]]; then
            IPV6_EXPANDED=$(sipcalc -6 "$1" | grep 'Expanded Address' | awk '{print $NF}')
            IPV6_PREFIX=''${IPV6_EXPANDED%:*:*:*:*}
            echo -n "$IPV6_PREFIX"
          fi
        }

        IPV6=$(ip -j -6 a show dev ${cfg.prefixInterface} scope global | jq -r '.[0].addr_info[] | select(.local[:2] != "fc" and .local[:2] != "fd").local')
        IPV6_PREFIX=$(get_prefix "$IPV6")
        if [[ -z "$IPV6_PREFIX" ]]; then exit; fi

        POOL_IPV6=$(swanctl --list-pools -n ${cfg.poolName} | awk '{print $2}')
        POOL_IPV6_PREFIX=$(get_prefix "$POOL_IPV6")

        if [[ "$IPV6_PREFIX" != "$POOL_IPV6_PREFIX" ]]; then
          TEMP=$(mktemp)
          cat > "$TEMP" << EOF
          pools {
            ${cfg.extraPools}
            ${cfg.poolName} {
               addrs = $IPV6_PREFIX${cfg.suffix}/128
               dns = $IPV6_PREFIX::1
            }
          }
        EOF
          swanctl --load-pools -f "$TEMP"
          rm -f "$TEMP"
        fi
      '';
      serviceConfig = import ../lib/systemd-harden.nix // {
        Type = "oneshot";
        RestrictAddressFamilies = [ "AF_UNIX" "AF_INET" "AF_INET6" "AF_NETLINK" ];
        PrivateNetwork = false;
        PrivateUsers = false;
        DynamicUser = false;
        ReadWritePaths = [ "/run" "/var/run" ];
      };
    };

    systemd.timers."swanctl-dynamic-ipv6" = {
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnStartupSec = 60;
        OnUnitActiveSec = 300;
      };
    };
  };
}
