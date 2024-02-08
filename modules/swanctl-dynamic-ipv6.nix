{ config, lib, pkgs, self, ... }:
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

    services.swanctlDynamicIPv6.IPv6Middle = mkOption {
      type = types.str;
      default = ":1";
    };

    services.swanctlDynamicIPv6.IPv4Prefix = mkOption {
      type = types.str;
      default = "10.6.6.";
    };

    services.swanctlDynamicIPv6.ULAPrefix = mkOption {
      type = types.str;
      default = "fd64::";
    };

    services.swanctlDynamicIPv6.local = mkOption {
      type = types.attrs;
      default = { };
    };

    services.swanctlDynamicIPv6.cacerts = mkOption {
      type = types.listOf types.str;
      default = [ ];
    };

    services.swanctlDynamicIPv6.devices = mkOption {
      type = types.listOf types.str;
      default = [ ];
    };
  };

  config = mkIf (builtins.length cfg.devices > 0) {
    services.strongswan-swanctl = {
      enable = true;
      swanctl = {
        connections = builtins.listToAttrs (lib.imap0
          (id: name: {
            inherit name;
            value = {
              local = cfg.local;
              remote.${name} = {
                auth = "pubkey";
                id = "${name}@rvf6.com";
                cacerts = cfg.cacerts;
              };
              children.${name} = {
                local_ts = [ "0.0.0.0/0" "::/0" ];
                life_time = "5d";
                rand_time = "10m";
              };
              version = 2;
              pools = [ "${name}_vip" "${name}_vip6" "${name}_vip_ula" ];
              rekey_time = "7d";
            };
          })
          cfg.devices);
        pools = builtins.listToAttrs (lib.flatten (lib.imap0
          (id: name: [
            {
              name = "${name}_vip";
              value = {
                addrs = "${cfg.IPv4Prefix}${toString (128 + id)}/32";
                dns = [ "${cfg.IPv4Prefix}1" ];
              };
            }
            {
              name = "${name}_vip6";
              value = {
                addrs = "${cfg.ULAPrefix}${lib.toHexString (128 + id)}/128";
                dns = [ "${cfg.ULAPrefix}1" ];
              };
            }
          ])
          cfg.devices));
      };
      strongswan.extraConfig = ''
        charon {
          install_routes = no
        }
      '';
    };

    systemd.services."swanctl-dynamic-ipv6" = {
      wants = [ "network-online.target" ];
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

        IPV6=$(ip -j -6 a show dev ${cfg.prefixInterface} scope global | jq -r '[.[0].addr_info[] | select(.local[:2] != "fc" and .local[:2] != "fd" and .local != null)][0].local')
        IPV6_PREFIX=$(get_prefix "$IPV6")
        if [[ -z "$IPV6_PREFIX" ]]; then exit; fi

        NEED_UPDATE=0
        ${builtins.concatStringsSep "" (map (device: ''
          POOL_IPV6=$(swanctl --list-pools -n ${device}_vip6 | awk '{print $2}')
          POOL_IPV6_PREFIX=$(get_prefix "$POOL_IPV6")
          if [[ "$IPV6_PREFIX" != "$POOL_IPV6_PREFIX" ]]; then
            NEED_UPDATE=1
          fi
        '') cfg.devices)}

        if [[ $NEED_UPDATE -eq 1 ]]; then
          TEMP=$(mktemp)
          cat > "$TEMP" << EOF
          pools {
            ${builtins.concatStringsSep "" (lib.imap0 (id: name: ''
              ${name}_vip {
                addrs = ${cfg.IPv4Prefix}${toString (128 + id)}/32
                dns = ${cfg.IPv4Prefix}1
              }
              ${name}_vip6 {
                addrs = $IPV6_PREFIX${cfg.IPv6Middle}::${lib.toHexString (id + 2)}/128
                dns = $IPV6_PREFIX::1
              }
              # ${name}_vip_ula {
              #   addrs = ${cfg.ULAPrefix}${lib.toHexString (128 + id)}/128
              #   dns = ${cfg.ULAPrefix}1
              # }
            '') cfg.devices)}
          }
        EOF
          swanctl --load-pools -f "$TEMP"
          rm -f "$TEMP"
        fi
      '';
      serviceConfig = self.data.systemdHarden // {
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
