{
  config,
  lib,
  self,
  ...
}:
let
  inherit (import ../../modules/swanctl-gfw/common.nix { inherit config lib self; })
    # keep-sorted start
    proposals
    # keep-sorted end
    ;
  interface = "xfrm-jp3-jp2";
  ifId = 4;
  table = 256;

  ipv4 = "10.5.0.130";
  ipv6 = "fdc0::82";
in
{

  networking.firewall.extraForwardRules = ''
    iifname ${interface} accept
  '';

  systemd.network = {
    netdevs."25-${interface}" = {
      netdevConfig = {
        Name = interface;
        Kind = "xfrm";
      };
      xfrmConfig = {
        InterfaceId = ifId;
        Independent = true;
      };
    };
    networks."25-${interface}" = {
      name = interface;
      address = [
        "${ipv4}/30"
        "${ipv6}/126"
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
          IncomingInterface = "xfrm-jp3";
          Priority = 64;
          Family = "both";
          Table = table;
        }
      ];
    };
  };

  services.strongswan-swanctl.swanctl.connections.jp2 = {
    inherit proposals;
    remote_addrs = [ self.data.dns.jp2.ipv6 ];
    local.jp3 = {
      auth = "pubkey";
      id = "jp3.rvf6.com";
      certs = [ config.sops.secrets."pki/jp3-bundle".path ];
    };
    remote.jp2 = {
      auth = "pubkey";
      id = "jp2.rvf6.com";
      cacerts = [
        config.sops.secrets."pki/ca".path
        config.sops.secrets."pki/ybk".path
      ];
    };
    children.jp2 = {
      local_ts = [
        "0.0.0.0/0"
        "::/0"
      ];
      remote_ts = [
        "0.0.0.0/0"
        "::/0"
      ];
      esp_proposals = proposals;
      start_action = "trap|start";
    };
    encap = false;
    mobike = false;
    version = 2;
    if_id_in = toString ifId;
    if_id_out = toString ifId;
  };

}
