{
  config,
  lib,
  pkgs,
  self,
  ...
}:
let
  inherit (lib)
    mkIf
    mkOption
    mkEnableOption
    mkMerge
    types
    toLower
    toHexString
    mapAttrsToList
    filterAttrs
    optional
    optionals
    optionalAttrs
    elem
    attrNames
    findFirst
    listToAttrs
    ;

  cfg = config.presets.wireguard.wg0;
  wg0 = self.data.wg0;
  host = config.networking.hostName;
  peer = wg0.peers.${host};
  net = wg0.networks.${host} or null;
  wgMark = 1;
  wgTable = 10;
  routeMark = 2;

  # from outPeers
  reverseClientPeers = attrNames (filterAttrs (_: c: elem host (c.outPeers or [ ])) wg0.networks);
  clientPeers = attrNames cfg.clientPeers;
  routePeer = findFirst (_: true) null (
    attrNames (filterAttrs (_: p: p.route != null) cfg.clientPeers)
  );
  route = if (routePeer != null) then cfg.clientPeers.${routePeer}.route else null;

  toLowerHex = n: toLower (toHexString n);
  toEndpoint = h: "${self.data.dns.${h}.ipv4}:${toString wg0.peers.${h}.port}";
  toAddress = net: peer: [
    "${net.ipv4Pre}${toString peer.id}/${toString net.ipv4Mask}"
    "${net.ipv6Pre}${toLowerHex peer.id}/${toString net.ipv6Mask}"
  ];
  toAllowedIPs = peer: [
    "${net.ipv4Pre}${toString peer.id}/32"
    "${net.ipv6Pre}${toLowerHex peer.id}/128"
  ];
  toClientPort = h: if (peer ? port) then peer.port + wg0.peers.${h}.id else null;

  clientPeerOptions =
    { config, name, ... }:
    {
      options = {
        endpoint = mkOption {
          type = with types; nullOr str;
          default = toEndpoint name;
        };

        keepalive = mkOption {
          type = with types; nullOr int;
          default = null;
        };

        route = mkOption {
          type =
            with types;
            nullOr (enum [
              "all"
              "cn"
            ]);
          default = null;
        };

        routeBypass = mkOption {
          type = with types; listOf str;
          default = [ ];
        };

        mark = mkOption {
          type = with types; nullOr int;
          default = if name == routePeer then wgMark else null;
        };

        table = mkOption {
          type = with types; nullOr int;
          default = if name == routePeer then wgTable else (100 + wg0.peers.${name}.id);
        };

        mtu = mkOption {
          type = types.int;
          default = cfg.mtu;
        };
      };
    };
in
{
  options.presets.wireguard.wg0 = {

    enable = mkEnableOption "";

    mtu = mkOption {
      type = types.int;
      default = 1420;
    };

    dynamicIPv6 = mkEnableOption "";

    clientPeers = mkOption {
      type = with types; attrsOf (submodule clientPeerOptions);
      default = { };
    };

  };

  config = mkIf cfg.enable (mkMerge [
    # server
    (mkIf (net != null) {

      networking.firewall = {
        allowedUDPPorts = [ peer.port ];
        extraForwardRules = ''
          iifname wg-${host} accept
        '';
      };

      systemd.network.config.networkConfig = {
        IPv4Forwarding = true;
        IPv6Forwarding = true;
      };

      systemd.network.netdevs."25-wg-${host}" = {
        netdevConfig = {
          Name = "wg-${host}";
          Kind = "wireguard";
          MTUBytes = toString cfg.mtu;
        };
        wireguardConfig = {
          PrivateKeyFile = config.sops.secrets.wireguard_key.path;
          ListenPort = peer.port;
        };
        wireguardPeers = (
          mapAttrsToList (
            h: p:
            {
              AllowedIPs = toAllowedIPs p;
              PublicKey = p.pubkey;
            }
            // (optionalAttrs (elem h (net.outPeers or [ ])) {
              Endpoint = "${self.data.dns.${h}.ipv4}:${toString (p.port + peer.id)}";
              PersistentKeepalive = 25;
            })
          ) (filterAttrs (h: _: h != host) wg0.peers)
        );
      };

      systemd.network.networks."25-wg-${host}" =
        {
          name = "wg-${host}";
          address = toAddress net peer;
          networkConfig.IPMasquerade = "both";
        }
        // (optionalAttrs cfg.dynamicIPv6 {
          networkConfig = {
            DHCPPrefixDelegation = true;
          };
          dhcpPrefixDelegationConfig = {
            Token = "::1";
          };
          linkConfig = {
            RequiredForOnline = false;
          };
        });

      presets.wireguard.dynamicIPv6.interfaces = optional cfg.dynamicIPv6 "wg-${host}";

    })

    # client
    {
      environment.systemPackages = with pkgs; [
        wireguard-tools
      ];

      networking.firewall.allowedUDPPorts = optionals (peer ? port) (map toClientPort reverseClientPeers);

      networking.nftables = {
        masquerade = map (h: ''oifname "wg-${h}"'') (reverseClientPeers ++ clientPeers);
        markChinaIP = mkIf (route == "cn") {
          enable = true;
          mark = routeMark;
        };
      };

      systemd.network.netdevs = listToAttrs (
        map (h: {
          name = "25-wg-${h}";
          value = {
            netdevConfig = {
              Name = "wg-${h}";
              Kind = "wireguard";
              MTUBytes = toString (cfg.clientPeers.${h}.mtu or cfg.mtu);
            };
            wireguardConfig = (
              filterAttrs (_: v: v != null) {
                PrivateKeyFile = config.sops.secrets.wireguard_key.path;
                ListenPort = toClientPort h;
                FirewallMark = cfg.clientPeers.${h}.mark or null;
                RouteTable = cfg.clientPeers.${h}.table or null;
              }
            );
            wireguardPeers = [
              (filterAttrs (_: v: v != null) {
                AllowedIPs = [
                  "0.0.0.0/0"
                  "::/0"
                ];
                PublicKey = wg0.peers.${h}.pubkey;
                Endpoint = cfg.clientPeers.${h}.endpoint or null;
                PersistentKeepalive = cfg.clientPeers.${h}.keepalive or null;
              })
            ];
          };
        }) (reverseClientPeers ++ clientPeers)
      );

      systemd.network.networks = listToAttrs (
        map (h: {
          name = "25-wg-${h}";
          value =
            {
              name = "wg-${h}";
              address = toAddress wg0.networks.${h} peer;
              routingPolicyRules = optional (cfg.clientPeers ? ${h}) {
                Family = "both";
                FirewallMark = cfg.clientPeers.${h}.table;
                Table = cfg.clientPeers.${h}.table;
                Priority = 1024;
              };
            }
            // (optionalAttrs (h == routePeer) {
              dns = [ "${wg0.networks.${h}.ipv6Pre}${toLowerHex wg0.peers.${h}.id}" ];
              domains = [ "~." ];
              networkConfig = {
                DNSDefaultRoute = "yes";
              };
              routingPolicyRules =
                map (ip: {
                  To = ip;
                  Priority = 128;
                }) cfg.clientPeers.${h}.routeBypass
                ++ (
                  if route == "all" then
                    [
                      {
                        Family = "both";
                        FirewallMark = wgMark;
                        InvertRule = "yes";
                        Table = wgTable;
                        Priority = 16384;
                      }
                    ]
                  else
                    [
                      {
                        Family = "both";
                        FirewallMark = wgMark;
                        Priority = 64;
                      }
                      {
                        Family = "both";
                        FirewallMark = routeMark;
                        Table = wgTable;
                        Priority = 16384;
                      }
                    ]
                );
            });
        }) (reverseClientPeers ++ clientPeers)
      );

      presets.wireguard.keepAlive.interfaces = map (x: "wg-${x}") clientPeers;

      #presets.wireguard.reResolve.interfaces = optional (cfg.route != null) "wg0";

      #presets.bpf-mark = mkIf (cfg.route != null) {
      #  wg0-re-resolve = wgMark;
      #};
    }

  ]);
}
