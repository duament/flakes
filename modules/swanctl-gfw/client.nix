{
  # keep-sorted start
  config,
  lib,
  self,
  # keep-sorted end
  ...
}:
let
  inherit (lib)
    # keep-sorted start
    imap0
    mkEnableOption
    mkIf
    mkMerge
    # keep-sorted end
    ;

  inherit (import ./common.nix { inherit config lib self; })
    # keep-sorted start
    ifId
    ifName
    ifsNft
    peerKey
    peers
    proposals
    # keep-sorted end
    ;

  cfg = config.presets.swanctl-gfw;

in
{

  options.presets.swanctl-gfw.enableClient = mkEnableOption "";

  config = mkIf cfg.enableClient (
    mkMerge (
      [
        {
          networking.firewall.extraForwardRules = ''
            iifname @wan_enabled_ifs oifname { ${ifsNft peers} } accept
          '';
        }
      ]
      ++ (imap0 (
        i: peer:
        let
          interfaceId = ifId i;
        in
        {

          systemd.network.netdevs."25-${ifName peer}" = {
            netdevConfig = {
              Name = ifName peer;
              Kind = "xfrm";
            };
            xfrmConfig = {
              InterfaceId = interfaceId;
              Independent = true;
            };
          };

          systemd.network.networks."25-${ifName peer}" = {
            name = ifName peer;
            address = [
              "${peer.clientIPv4}/30"
              "${peer.clientIPv6}/126"
            ];
          };

          services.strongswan-swanctl = {
            enable = true;
            swanctl = {
              connections.${peerKey peer} = {
                inherit proposals;
                remote_addrs = [ peer.remote ];
                local = config.presets.swanctl.local;
                remote.${peerKey peer} = {
                  auth = "pubkey";
                  id = "${peer.host}.rvf6.com";
                  cacerts = config.presets.swanctl.cacerts;
                };
                children.${peerKey peer} = {
                  start_action = "trap|start";
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
                encap = peer.encap;
                mobike = false;
                version = 2;
                if_id_in = toString interfaceId;
                if_id_out = toString interfaceId;
              };
            };
          };

        }
      ) peers)
    )
  );

}
