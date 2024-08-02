{ config, lib, pkgs, ... }:
let
  inherit (lib) length listToAttrs flatten imap0 toHexString mkIf mkOption mkEnableOption types;
  cfg = config.presets.swanctl;
in
{
  options.presets.swanctl = {
    enable = mkEnableOption "";

    interface = mkOption {
      type = types.str;
      default = "xfrm0";
    };

    underlyingNetwork = mkOption {
      type = types.str;
      example = "10-eth0";
    };

    IPv4Prefix = mkOption {
      type = types.str;
      default = "10.6.6.";
    };

    IPv6Prefix = mkOption {
      type = types.str;
      default = "2606:4700:110:8395::";
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
    networking.nftables.masquerade = [ "iifname ${cfg.interface} meta nfproto ipv6" ];

    systemd.network.networks.${cfg.underlyingNetwork}.xfrm = [ cfg.interface ];

    systemd.network.netdevs."25-${cfg.interface}" = {
      netdevConfig = { Name = cfg.interface; Kind = "xfrm"; };
      xfrmConfig.InterfaceId = 1;
    };
    systemd.network.networks."25-${cfg.interface}" = {
      name = cfg.interface;
      address = [ "${cfg.IPv4Prefix}1/24" "${cfg.IPv6Prefix}1/120" ];
      routingPolicyRules = [
        {
          To = "${cfg.IPv6Prefix}1/120";
          Priority = 5;
        }
      ];
    };

    services.strongswan-swanctl = {
      enable = true;
      swanctl = {
        connections = listToAttrs (imap0
          (id: name: {
            inherit name;
            value = {
              local = cfg.local;
              remote.${name} = {
                auth = "pubkey";
                id = "${name}@rvf6.com";
                cacerts = cfg.cacerts;
              };
              children.${name}.local_ts = [ "0.0.0.0/0" "::/0" ];
              version = 2;
              pools = [ "${name}_vip" "${name}_vip6" ];
              if_id_in = "1";
              if_id_out = "1";
            };
          })
          cfg.devices);
        pools = listToAttrs (flatten (imap0
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
                addrs = "${cfg.IPv6Prefix}${toHexString (128 + id)}/128";
                dns = [ "${cfg.IPv6Prefix}1" ];
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

    systemd.services.strongswan-swanctl.serviceConfig.ExecStartPre = [
      "+${pkgs.coreutils}/bin/ln -nsf ${cfg.privateKeyFile} /etc/swanctl/private/private.key"
    ];

  };
}
