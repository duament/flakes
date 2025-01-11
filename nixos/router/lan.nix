{
  config,
  lib,
  ...
}:
let
  inherit (lib)
    nameValuePair
    listToAttrs
    imap1
    length
    filter
    elem
    subtractLists
    concatStringsSep
    toHexString
    mkOption
    types
    ;
  inherit (lib.lists) findFirstIndex;

  bridgeName = "br-lan";
  vlans = [
    "lan"
    "gaming"
    "guest"
    "internet"
    "iot"
  ];
  unmanagedVlans = [
    "gaming"
  ];
  managedVlans = subtractLists unmanagedVlans vlans;

  vlanRange = "1-${toString (length vlans)}";

  # VLAN interface name
  ifName =
    name:
    let
      i = (findFirstIndex (x: x == name) null vlans) + 1;
    in
    "v${toString i}-${name}";
  ifName1 = i: name: "v${toString i}-${name}";
in
{

  options.router = {

    lanIfs = mkOption {
      type = types.listOf types.str;
      apply = v: concatStringsSep ", " v;
    };

    lanEnabledIfs = mkOption {
      type = types.listOf types.str;
      default = [ ];
      apply = v: concatStringsSep ", " v;
    };

  };

  config = {

    router = {
      lanIfs = map ifName managedVlans;
      lanEnabledIfs = map ifName [
        "lan"
      ];
      wgEnabledIfs = map ifName [
        "lan"
      ];
      wanEnabledIfs = map ifName managedVlans;
      dnsEnabledIfs = map ifName managedVlans;
    };

    networking.firewall = {
      extraInputRules = ''
        iifname { ${config.router.lanIfs} } udp dport 67 accept
      '';
      extraForwardRules = ''
        iifname { ${config.router.lanEnabledIfs} } oifname { ${config.router.lanIfs} } accept
      '';
    };

    systemd.network.netdevs =
      {
        "25-${bridgeName}" = {
          netdevConfig = {
            Name = bridgeName;
            Kind = "bridge";
          };
          bridgeConfig = {
            DefaultPVID = "none";
            VLANFiltering = true;
          };
        };
      }
      // (listToAttrs (
        imap1 (
          i: name:
          nameValuePair "30-${ifName name}" {
            netdevConfig = {
              Name = ifName name;
              Kind = "vlan";
            };
            vlanConfig.Id = i;
          }
        ) vlans
      ));

    systemd.network.networks =
      {
        "25-${bridgeName}" = {
          name = bridgeName;
          networkConfig.VLAN = imap1 ifName1 vlans;
          bridgeVLANs = [ { VLAN = vlanRange; } ];
        };
        "50-enp2s0" = {
          name = "enp2s0";
          networkConfig.Bridge = bridgeName;
          bridgeVLANs = [
            {
              VLAN = 1;
              EgressUntagged = 1;
              PVID = 1;
            }
            { VLAN = "2-4"; }
          ];
        };
        "50-enp3s0" = {
          name = "enp3s0";
          networkConfig.Bridge = bridgeName;
          bridgeVLANs = [
            { VLAN = vlanRange; }
          ];
        };
        "50-enp4s0" = {
          name = "enp4s0";
          networkConfig.Bridge = bridgeName;
          bridgeVLANs = [
            { VLAN = vlanRange; }
          ];
        };
      }
      // (listToAttrs (
        filter (v: v != null) (
          imap1 (
            i: name:
            if (elem name unmanagedVlans) then
              null
            else
              nameValuePair "30-${ifName name}" {
                name = ifName name;
                address = [
                  "10.8.${toString (i - 1)}.1/24"
                  "fdd${toHexString (i - 1)}::1/64"
                ];
                ipv6Prefixes = [ { Prefix = "fdd${toHexString (i - 1)}::/64"; } ];
                networkConfig = {
                  DHCPServer = true;
                  IPv6SendRA = true;
                  DHCPPrefixDelegation = true;
                  IPv4Forwarding = true;
                  IPv6Forwarding = true;
                };
                dhcpServerConfig = {
                  DNS = "_server_address";
                };
                ipv6SendRAConfig = {
                  DNS = "_link_local";
                };
              }
          ) vlans
        )
      ));

    services.uu = {
      enable = true;
      extraInterfaces = [
        (ifName "gaming")
      ];
    };

  };

}
