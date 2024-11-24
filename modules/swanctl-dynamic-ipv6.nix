{
  config,
  lib,
  pkgs,
  self,
  ...
}:
let
  inherit (lib)
    length
    listToAttrs
    concatStringsSep
    flatten
    imap0
    toHexString
    mkIf
    mkOption
    mkEnableOption
    types
    ;
  cfg = config.services.swanctlDynamicIPv6;

  vip6Path = "/var/lib/swanctl-dynamic-ipv6/vip6.conf";
in
{
  options.services.swanctlDynamicIPv6 = {
    enable = mkEnableOption "";

    interface = mkOption {
      type = types.str;
      default = "xfrm0";
    };

    underlyingNetwork = mkOption {
      type = types.str;
      example = "10-eth0";
    };

    IPv6Middle = mkOption {
      type = types.str;
      default = ":1";
    };

    IPv4Prefix = mkOption {
      type = types.str;
      default = "10.6.6.";
    };

    ULAPrefix = mkOption {
      type = types.str;
      default = "fd64::";
    };

    privateKeyFile = mkOption {
      type = types.path;
    };

    local = mkOption {
      type = types.attrs;
      default = { };
    };

    cacerts = mkOption {
      type = types.listOf types.str;
      default = [ ];
    };

    devices = mkOption {
      type = types.listOf types.str;
      default = [ ];
    };
  };

  config = mkIf (cfg.enable && (length cfg.devices > 0)) {

    networking.firewall = {
      checkReversePath = "loose";
      allowedUDPPorts = [
        500 # IPsec
        4500 # IPsec
      ];
      extraInputRules = ''
        ip protocol { ah, esp } accept
        ip6 nexthdr { ah, esp } accept
        iifname ${cfg.interface} meta l4proto { tcp, udp } th dport 53 accept
      '';
      extraForwardRules = ''
        iifname ${cfg.interface} accept
      '';
    };
    networking.nftables.checkRuleset = false;

    systemd.network.networks.${cfg.underlyingNetwork}.xfrm = [ cfg.interface ];

    systemd.network.netdevs."25-${cfg.interface}" = {
      netdevConfig = {
        Name = cfg.interface;
        Kind = "xfrm";
      };
      xfrmConfig.InterfaceId = 1;
    };
    systemd.network.networks."25-${cfg.interface}" = {
      name = cfg.interface;
      address = [ "${cfg.IPv4Prefix}1/24" ];
      networkConfig.DHCPPrefixDelegation = true;
      dhcpPrefixDelegationConfig.Token = "::1";
    };

    services.strongswan-swanctl = {
      enable = true;
      includes = [ vip6Path ];
      swanctl = {
        connections = listToAttrs (
          imap0 (id: name: {
            inherit name;
            value = {
              local = cfg.local;
              remote.${name} = {
                auth = "pubkey";
                id = "${name}@rvf6.com";
                cacerts = cfg.cacerts;
              };
              children.${name}.local_ts = [
                "0.0.0.0/0"
                "::/0"
              ];
              version = 2;
              pools = [
                "${name}_vip"
                "${name}_vip6"
                "${name}_vip_ula"
              ];
              if_id_in = "1";
              if_id_out = "1";
            };
          }) cfg.devices
        );
        pools = listToAttrs (
          flatten (
            imap0 (id: name: [
              {
                name = "${name}_vip";
                value = {
                  addrs = "${cfg.IPv4Prefix}${toString (128 + id)}/32";
                  dns = [ "${cfg.IPv4Prefix}1" ];
                };
              }
              #{
              #  name = "${name}_vip6";
              #  value = {
              #    addrs = "${cfg.ULAPrefix}${toHexString (128 + id)}/128";
              #    dns = [ "${cfg.ULAPrefix}1" ];
              #  };
              #}
            ]) cfg.devices
          )
        );
      };
      strongswan.extraConfig = ''
        charon {
          install_routes = no
        }
      '';
    };

    systemd.services.strongswan-swanctl.serviceConfig.ExecStartPre = [
      "+${pkgs.coreutils}/bin/ln -nsf ${cfg.privateKeyFile} /etc/swanctl/private/private.key"
    ];

    systemd.services."swanctl-dynamic-ipv6" = {
      wants = [ "network-online.target" ];
      after = [ "network-online.target" ];
      path = with pkgs; [
        iproute2
        jq
        sipcalc
        gawk
        strongswan
      ];
      script = ''
        set -o pipefail

        get_prefix() {
          if [[ -n "$1" ]]; then
            IPV6_EXPANDED=$(sipcalc -6 "$1" | grep 'Expanded Address' | awk '{print $NF}')
            IPV6_PREFIX=''${IPV6_EXPANDED%:*:*:*:*}
            echo -n "$IPV6_PREFIX"
          fi
        }

        IPV6=$(ip -j -6 a show dev ${cfg.interface} scope global | jq -r '[.[0].addr_info[] | select(.local[:2] != "fc" and .local[:2] != "fd" and .local != null)][0].local')
        IPV6_PREFIX=$(get_prefix "$IPV6")
        if [[ -z "$IPV6_PREFIX" ]]; then exit; fi

        NEED_UPDATE=0
        ${concatStringsSep "" (
          map (device: ''
            POOL_IPV6=$(swanctl --list-pools -n ${device}_vip6 | awk '{print $2}')
            POOL_IPV6_PREFIX=$(get_prefix "$POOL_IPV6")
            if [[ "$IPV6_PREFIX" != "$POOL_IPV6_PREFIX" ]]; then
              NEED_UPDATE=1
            fi
          '') cfg.devices
        )}

        if [[ $NEED_UPDATE -eq 1 ]]; then
          cat > "${vip6Path}.tmp" << EOF
          pools {
            ${
              concatStringsSep "" (
                imap0 (id: name: ''
                  # ${name}_vip {
                  #   addrs = ${cfg.IPv4Prefix}${toString (128 + id)}/32
                  #   dns = ${cfg.IPv4Prefix}1
                  # }
                  ${name}_vip6 {
                    addrs = $IPV6_PREFIX${cfg.IPv6Middle}::${toHexString (id + 2)}/128
                    dns = $IPV6_PREFIX::1
                  }
                  # ${name}_vip_ula {
                  #   addrs = ${cfg.ULAPrefix}${toHexString (128 + id)}/128
                  #   dns = ${cfg.ULAPrefix}1
                  # }
                '') cfg.devices
              )
            }
          }
        EOF
          mv "${vip6Path}.tmp" "${vip6Path}"
          systemctl restart strongswan-swanctl.service
        fi
      '';
      serviceConfig = self.data.systemdHarden // {
        Type = "oneshot";
        RestrictAddressFamilies = [
          "AF_UNIX"
          "AF_INET"
          "AF_INET6"
          "AF_NETLINK"
        ];
        PrivateNetwork = false;
        PrivateUsers = false;
        DynamicUser = false;
        ReadWritePaths = [
          "/run"
          "/var/run"
        ];
        StateDirectory = "%N";
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
