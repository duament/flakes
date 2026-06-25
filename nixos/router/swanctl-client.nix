{
  config,
  lib,
  self,
  ...
}:
let
  inherit (lib)
    elemAt
    imap0
    mkMerge
    concatStringsSep
    ;

  cfg = [
    rec {
      host = "de";
      remote = self.data.dns.${host}.ipv6;
      address = [
        "10.5.0.2/30"
        "fdc0::2/126"
      ];
    }
    rec {
      host = "nl";
      remote = self.data.dns.${host}.ipv6;
      address = [
        "10.5.0.18/30"
        "fdc0::12/126"
      ];
    }
    rec {
      host = "de2";
      remote = self.data.dns.${host}.ipv4;
      address = [
        "10.5.0.34/30"
        "fdc0::22/126"
      ];
    }
  ];

  hosts = map (x: x.host) cfg;
  interface = host: "xfrm-${host}";
  proposals = [
    "aes256gcm16-prfsha384-curve25519-ke1_mlkem768"
  ];
in
{

  config = mkMerge (
    [
      {
        networking.firewall.extraForwardRules = ''
          iifname @wan_enabled_ifs oifname { ${
            concatStringsSep ", " (map (x: ''"${interface x}"'') hosts)
          } } accept
        '';
      }
    ]
    ++ (imap0 (
      i: host:
      let
        interfaceId = i + 16;
        hostCfg = elemAt cfg i;
      in
      {

        systemd.network.netdevs."25-${interface host}" = {
          netdevConfig = {
            Name = interface host;
            Kind = "xfrm";
          };
          xfrmConfig = {
            InterfaceId = interfaceId;
            Independent = true;
          };
        };

        systemd.network.networks."25-${interface host}" = {
          name = interface host;
          address = hostCfg.address;
        };

        services.strongswan-swanctl = {
          enable = true;
          swanctl = {
            connections.${host} = {
              inherit proposals;
              remote_addrs = [ hostCfg.remote ];
              local = config.presets.swanctl.local;
              remote.${host} = {
                auth = "pubkey";
                id = "${host}.rvf6.com";
                cacerts = config.presets.swanctl.cacerts;
              };
              children.${host} = {
                start_action = "start";
                esp_proposals = proposals;
                set_mark_out = "1";
                local_ts = [
                  "::/0"
                  "0.0.0.0/0"
                ];
                remote_ts = [
                  "::/0"
                  "0.0.0.0/0"
                ];
              };
              encap = false;
              mobike = false;
              version = 2;
              if_id_in = toString interfaceId;
              if_id_out = toString interfaceId;
            };
          };
        };

      }
    ) hosts)
  );

}
