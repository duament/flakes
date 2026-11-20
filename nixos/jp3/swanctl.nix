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
  peer = "jp";
  interface = "xfrm-jp3-${peer}";
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
    config.routeTables.${interface} = table;
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
          Table = interface;
        }
        {
          Source = "::/0";
          Table = interface;
        }
      ];
      routingPolicyRules = [
        {
          IncomingInterface = "xfrm-jp3";
          Priority = 128;
          Family = "both";
          Table = interface;
        }
        {
          IncomingInterface = interface;
          Priority = 128;
          Family = "both";
          Table = "xfrm-jp3";
        }
      ];
    };
  };

  services.strongswan-swanctl.swanctl.connections.${peer} = {
    inherit proposals;
    remote_addrs = [ self.data.dns.${peer}.ipv6 ];
    local.jp3 = {
      auth = "pubkey";
      id = "jp3.rvf6.com";
      certs = [ config.sops.secrets."pki/jp3-bundle".path ];
    };
    remote.${peer} = {
      auth = "pubkey";
      id = "${peer}.rvf6.com";
      cacerts = [
        config.sops.secrets."pki/ca".path
        config.sops.secrets."pki/ybk".path
      ];
    };
    children.${peer} = {
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
