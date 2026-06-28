{
  config,
  lib,
  self,
}:
let
  inherit (lib) concatStringsSep filter optionalString;
in
rec {

  peerKey = peer: peer.host + (optionalString (peer.key != "") "-${peer.key}");

  ifId = i: i + 16;

  ifName = peer: "xfrm-${peerKey peer}";

  # convert interfaces in peers to nft set format (without { })
  ifsNft = peers: concatStringsSep ", " (map (peer: ''"${ifName peer}"'') peers);

  peers = self.data.swanctl-gfw;

  proposals = [
    "aes256gcm16-prfsha384-curve25519-ke1_mlkem768"
  ];

  serverPeers = filter (p: p.host == config.networking.hostName) peers;

  pkcs8 = host: config.sops.secrets."pki/${host}-pkcs8-key".path;

  proxyPort = 8000;

}
