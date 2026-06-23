{
  config,
  lib,
  self,
  ...
}:
let
  inherit (lib) imap0 mkMerge attrNames;

  addresses = {
    de = [
      "10.5.0.2/30"
      "fdc0::2/126"
    ];
    nl = [
      "10.5.0.18/30"
      "fdc0::12/126"
    ];
  };

  hosts = attrNames addresses;
  interface = host: "xfrm-${host}";
  proposals = [
    "aes256gcm16-prfsha384-curve25519-ke1_mlkem768"
  ];
in
{

  config = mkMerge (
    imap0 (
      i: host:
      let
        interfaceId = i + 16;
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
          address = addresses.${host};
        };

        services.strongswan-swanctl = {
          enable = true;
          swanctl = {
            connections.${host} = {
              inherit proposals;
              remote_addrs = [ self.data.dns.${host}.ipv6 ];
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
    ) hosts
  );

}
