{ config, lib, self, ... }:
let
  cfg = config.presets.wireguard.wg0;
  wg0 = self.data.wg0;
  peer = wg0.peers.${config.networking.hostName};
  control = wg0.peers.${wg0.control};
  isControl = config.networking.hostName == wg0.control;
  isP2p = builtins.elem config.networking.hostName wg0.p2p;
  wgMark = 1;
  wgTable = 10;
  routeMark = 2;
  dns = [ "${wg0.ipv6Pre}${toLowerHex control.id}" ];

  toLowerHex = n: lib.toLower (lib.toHexString n);
  toEndpoint = peer: "${peer.addr}:${toString peer.port}";
  toAddress = peer: [
    "${wg0.ipv4Pre}${toString peer.id}/${toString wg0.ipv4Mask}"
    "${wg0.ipv6Pre}${toLowerHex peer.id}/${toString wg0.ipv6Mask}"
  ];
  toAllowedIPs = peer: [
    "${wg0.ipv4Pre}${toString peer.id}/32"
    "${wg0.ipv6Pre}${toLowerHex peer.id}/128"
  ];
in
{
  options = {
    presets.wireguard.wg0.enable = lib.mkEnableOption "";

    presets.wireguard.wg0.mtu = lib.mkOption {
      type = lib.types.int;
      default = 1420;
    };

    presets.wireguard.wg0.route = lib.mkOption {
      type = with lib.types; nullOr (enum [ "all" "cn" ]);
      default = null;
    };

    presets.wireguard.wg0.routeBypass = lib.mkOption {
      type = with lib.types; listOf str;
      default = [ ];
    };
  };

  config = lib.mkIf cfg.enable (lib.mkMerge [
    {
      networking.firewall.allowedUDPPorts = lib.optional (peer ? port) peer.port;

      networking.nftables = lib.mkIf (cfg.route == "cn") {
        masquerade = [ "oifname \"wg0\"" ];
        markChinaIP = {
          enable = true;
          mark = routeMark;
        };
      };

      systemd.network.netdevs."25-wg0" = {
        netdevConfig = {
          Name = "wg0";
          Kind = "wireguard";
          MTUBytes = toString cfg.mtu;
        };
        wireguardConfig = {
          PrivateKeyFile = config.sops.secrets.wireguard_key.path;
        } // (if cfg.route == null then {
          ListenPort = peer.port;
        } else {
          FirewallMark = wgMark;
          RouteTable = wgTable;
        });
        wireguardPeers =
          if isControl then
            (map
              (peer: {
                wireguardPeerConfig = {
                  AllowedIPs = toAllowedIPs peer;
                  PublicKey = peer.pubkey;
                } // (lib.optionalAttrs (peer ? addr) {
                  Endpoint = toEndpoint peer;
                  PersistentKeepalive = 25;
                });
              })
              (builtins.attrValues (lib.filterAttrs (host: _: host != config.networking.hostName) wg0.peers))
            ) else [
            {
              wireguardPeerConfig = {
                AllowedIPs = [ "0.0.0.0/0" "::/0" ];
                PublicKey = control.pubkey;
              } // (lib.optionalAttrs (cfg.route != null) {
                Endpoint = toEndpoint control;
                PersistentKeepalive = 25;
              });
            }
          ];
      };

      systemd.network.networks."25-wg0" = {
        name = "wg0";
        address = toAddress peer;
      } // (lib.optionalAttrs isControl {
        networkConfig = { DHCPPrefixDelegation = true; };
        dhcpPrefixDelegationConfig = { Token = "::1"; };
        linkConfig = { RequiredForOnline = false; };
      }
      ) // (lib.optionalAttrs (cfg.route != null) {
        inherit dns;
        domains = [ "~." ];
        networkConfig = { DNSDefaultRoute = "yes"; };
        routingPolicyRules = map
          (ip:
            {
              routingPolicyRuleConfig = {
                To = ip;
                Priority = 9;
              };
            }
          )
          cfg.routeBypass ++ (if cfg.route == "all" then
          [
            {
              routingPolicyRuleConfig = {
                Family = "both";
                FirewallMark = wgMark;
                InvertRule = "yes";
                Table = wgTable;
                Priority = 10;
              };
            }
          ] else [
          {
            routingPolicyRuleConfig = {
              Family = "both";
              FirewallMark = wgMark;
              Priority = 9;
            };
          }
          {
            routingPolicyRuleConfig = {
              Family = "both";
              FirewallMark = routeMark;
              Table = wgTable;
              Priority = 10;
            };
          }
        ]);
      });

      presets.wireguard.dynamicIPv6.interfaces = lib.optional isControl "wg0";

      presets.wireguard.reResolve.interfaces = lib.optional (cfg.route != null) "wg0";

      presets.bpf-mark = lib.mkIf (cfg.route != null) {
        wg0-re-resolve = wgMark;
      };
    }

    (lib.mkIf isP2p {

      networking.firewall = {
        allowedUDPPorts = [ (11120 + peer.id) ];
        extraForwardRules = ''
          iifname wg-${config.networking.hostName} accept
        '';
      };

      networking.nftables.masquerade = [ "iifname wg-${config.networking.hostName}" ];

      systemd.network.netdevs."25-wg-${config.networking.hostName}" = {
        netdevConfig = {
          Name = "wg-${config.networking.hostName}";
          Kind = "wireguard";
          MTUBytes = toString cfg.mtu;
        };
        wireguardConfig = {
          PrivateKeyFile = config.sops.secrets.wireguard_key.path;
          ListenPort = 11120 + peer.id;
        };
        wireguardPeers = [{
          wireguardPeerConfig = {
            AllowedIPs = [ "0.0.0.0/0" "::/0" ];
            PublicKey = control.pubkey;
          };
        }];
      };

      systemd.network.networks."25-wg-${config.networking.hostName}" = {
        name = "wg-${config.networking.hostName}";
        address = [ "10.7.${toString peer.id}.2/24" "fd66:${toLowerHex peer.id}::2/120" ];
        networkConfig.IPForward = true;
      };

    })

    (lib.mkIf isControl {

      systemd.network = lib.mkMerge (map
        (host: {
          netdevs."25-wg-${host}" = {
            netdevConfig = {
              Name = "wg-${host}";
              Kind = "wireguard";
            };
            wireguardConfig = {
              PrivateKeyFile = config.sops.secrets.wireguard_key.path;
              FirewallMark = 3;
              RouteTable = 100 + wg0.peers.${host}.id;
            };
            wireguardPeers = [
              {
                wireguardPeerConfig = {
                  AllowedIPs = [ "0.0.0.0/0" "::/0" ];
                  PublicKey = wg0.peers.${host}.pubkey;
                  Endpoint = "${wg0.peers.${host}.addr}:${toString (11120 + wg0.peers.${host}.id)}";
                };
              }
            ];
          };
          networks."25-wg-${host}" = {
            name = "wg-${host}";
            address = [ "10.7.${toString wg0.peers.${host}.id}.1/24" "fd66:${toLowerHex wg0.peers.${host}.id}::1/120" ];
          };
        })
        wg0.p2p);

    })
  ]);
}
