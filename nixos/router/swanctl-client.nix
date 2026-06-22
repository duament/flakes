{
  config,
  self,
  ...
}:
let
  interface = "xfrm-de";
  interfaceId = 2;
  proposals = [
    "aes256gcm16-prfsha384-curve25519-ke1_mlkem768"
  ];
in
{

  systemd.network.netdevs."25-${interface}" = {
    netdevConfig = {
      Name = interface;
      Kind = "xfrm";
    };
    xfrmConfig = {
      InterfaceId = interfaceId;
      Independent = true;
    };
  };
  systemd.network.networks."25-${interface}" = {
    name = interface;
    address = [
      "10.5.0.2/30"
      "fdc0::2/126"
    ];
  };

  services.strongswan-swanctl = {
    enable = true;
    swanctl = {
      connections.de = {
        inherit proposals;
        remote_addrs = [ self.data.dns.de.ipv6 ];
        local = config.presets.swanctl.local;
        remote.de = {
          auth = "pubkey";
          id = "de.rvf6.com";
          cacerts = config.presets.swanctl.cacerts;
        };
        children.de = {
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
