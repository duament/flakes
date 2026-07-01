{
  # keep-sorted start
  config,
  lib,
  pkgs,
  self,
  # keep-sorted end
  ...
}:
let
  inherit (lib)
    # keep-sorted start
    concatMap
    concatStringsSep
    filter
    imap0
    listToAttrs
    mkEnableOption
    mkIf
    mkMerge
    optional
    # keep-sorted end
    ;

  inherit (import ./common.nix { inherit config lib self; })
    # keep-sorted start
    ifId
    ifName
    ifsNft
    peerKey
    pkcs8
    proposals
    proxyPort
    serverPeers
    # keep-sorted end
    ;

  cfg = config.presets.swanctl-gfw;

  masqueradeIfs = ifsNft (filter (peer: peer.masquerade) serverPeers);
in
{

  options.presets.swanctl-gfw.enableServer = mkEnableOption "";

  config = mkIf cfg.enableServer ({
    boot.kernel.sysctl = {
      "net.ipv4.ip_forward" = true;
      "net.ipv6.conf.all.forwarding" = true;
    };

    networking.firewall = {
      checkReversePath = "loose";
      allowedUDPPorts = [
        500 # IPsec
        4500 # IPsec
      ];
      interfaces = listToAttrs (
        map (peer: {
          name = ifName peer;
          value.allowedTCPPorts = [ proxyPort ];
        }) serverPeers
      );
      extraInputRules = ''
        ip protocol { ah, esp } accept
        ip6 nexthdr { ah, esp } accept
      '';
      extraForwardRules = ''
        iifname { ${ifsNft serverPeers} } accept
      '';
    };
    networking.nftables.checkRuleset = false;
    networking.nftables.masquerade = optional (masqueradeIfs != "") "iifname { ${masqueradeIfs} }";
    networking.nftables.tables.interface-mark = {
      family = "inet";
      content = concatStringsSep "\n" (
        imap0 (
          i: peer:
          let
            mark = 1024 + (ifId i);
          in
          ''
            chain ${ifName peer}-mark {
              type filter hook prerouting priority mangle;
              iifname ${ifName peer} ct state new ct mark set ${toString mark}
              ct direction reply ct mark ${toString mark} meta mark set ct mark
            }
            chain ${ifName peer}-mark-output {
              type route hook output priority mangle;
              ct direction reply ct mark ${toString mark} meta mark set ct mark
            }
          ''
        ) serverPeers
      );
    };

    systemd.network = mkMerge (
      imap0 (
        i: peer:
        let
          mark = 1024 + (ifId i);
          table = 1024 + (ifId i);
        in
        {
          netdevs."25-${ifName peer}" = {
            netdevConfig = {
              Name = ifName peer;
              Kind = "xfrm";
            };
            xfrmConfig = {
              InterfaceId = ifId i;
              Independent = true;
            };
          };
          networks."25-${ifName peer}" = {
            name = ifName peer;
            address = [
              "${peer.serverIPv4}/30"
              "${peer.serverIPv6}/126"
            ];
            routes = [
              {
                Source = "0.0.0.0/0";
                Table = table;
              }
              {
                Source = "::/0";
                Table = table;
              }
            ];
            routingPolicyRules = [
              {
                FirewallMark = mark;
                Priority = 64;
                Family = "both";
                Table = table;
              }
            ];
          };
        }
      ) serverPeers
    );

    services.strongswan-swanctl = {
      enable = true;
      swanctl.connections = listToAttrs (
        imap0 (i: peer: {
          name = peerKey peer;
          value = {
            inherit proposals;
            local.${peerKey peer} = {
              auth = "pubkey";
              id = "${peer.host}.rvf6.com";
              certs = [ config.sops.secrets."pki/${peer.host}-bundle".path ];
            };
            remote.router = {
              auth = "pubkey";
              id = "router.rvf6.com";
              cacerts = [
                config.sops.secrets."pki/ca".path
                config.sops.secrets."pki/ybk".path
              ];
            };
            children.${peerKey peer} = {
              local_ts = [
                "0.0.0.0/0"
                "::/0"
              ];
              remote_ts = [
                "0.0.0.0/0"
                "::/0"
              ];
              esp_proposals = proposals;
            };
            encap = peer.encap;
            mobike = false;
            version = 2;
            if_id_in = toString (ifId i);
            if_id_out = toString (ifId i);
          };
        }) serverPeers
      );
      strongswan.extraConfig = ''
        charon {
          install_routes = no
        }
      '';
    };

    systemd.services.strongswan-swanctl.serviceConfig.ExecStartPre = [
      "+${pkgs.coreutils}/bin/ln -nsf ${pkcs8 config.networking.hostName} /etc/swanctl/private/private.key"
    ];

    presets.sing-box = {
      enable = true;
      settings = {
        dns.servers = [
          {
            type = "local";
            tag = "local";
          }
        ];
        inbounds = concatMap (peer: [
          {
            type = "http";
            listen = peer.serverIPv4;
            listen_port = proxyPort;
          }
          {
            type = "http";
            listen = peer.serverIPv6;
            listen_port = proxyPort;
          }
        ]) serverPeers;
        outbounds = [
          {
            type = "direct";
            tag = "direct";
          }
        ];
        route.default_domain_resolver = "local";
      };
    };
  });

}
