with builtins;
rec {
  host = "h.rvf6.com";
  port = 11112;
  ipv4Pre = "10.6.6.";
  ipv6Pre = "fd64::";
  gateway4 = "${ipv4Pre}1";
  gateway6 = "${ipv6Pre}1";
  subnet4 = "${ipv4Pre}0/24";
  subnet6 = "${ipv6Pre}0/120";
  endpoint = "${host}:${toString port}";
  pubkey = "LKEU/VwW+TFNuHWwNzOhxh0FVjnfMYHE9bxSx2luNjw=";
  peers = {
    iphone = {
      ipv4 = "${ipv4Pre}2";
      ipv6 = "${ipv6Pre}2";
      pubkey = "BcLh8OUygmCL2m50MREgsAwOLMkF9A+eAhuQDEPaqWI=";
    };
    xiaoxin = {
      ipv4 = "${ipv4Pre}3";
      ipv6 = "${ipv6Pre}3";
      pubkey = "EB86zlOPDzQLKkByxWznf/deQiIssQ6LAcMuw2oDbRI=";
    };
    k2 = {
      ipv4 = "${ipv4Pre}4";
      ipv6 = "${ipv6Pre}4";
      pubkey = "Q+jZnY03JJc20cjwsP60CeClbxhYV9OU0jAEPqKNjTY=";
    };
    k1 = {
      ipv4 = "${ipv4Pre}5";
      ipv6 = "${ipv6Pre}5";
      pubkey = "XQss9kzHipmjizrqUsBYQltHuj3NvyR8+e0hLRfunQE=";
    };
    work = {
      ipv4 = "${ipv4Pre}10";
      ipv6 = "${ipv6Pre}a";
      pubkey = "Zwg16+rw0uVJHFWsKj56nc9+eli0/XIYrKxespMbGj0=";
    };
    or3 = {
      ipv4 = "${ipv4Pre}23";
      ipv6 = "${ipv6Pre}17";
      pubkey = "60W+Pr5CKSpiJ1tY8Dnz+D/vD+r0au3exf3NgZ5DMVM=";
      endpointAddr = "[2603:c020:2:8c00:79ea:4095:6b07:144d]"; # or3.rvf6.com
      endpointPort = 11111;
    };
    az = {
      ipv4 = "${ipv4Pre}24";
      ipv6 = "${ipv6Pre}18";
      pubkey = "K8CvTzxt9fEatQzYkhdxuxKfNrCQ/XXVhI2vLlRnESE=";
      endpointAddr = "104.208.105.145"; # az.rvf6.com
      endpointPort = 11111;
    };
  };
  peerConfigs = map (peer: {
    wireguardPeerConfig = {
      AllowedIPs = [ "${peer.ipv4}/32" "${peer.ipv6}/128" ];
      PublicKey = peer.pubkey;
    } // (if (peer ? endpointAddr) then {
      Endpoint = "${peer.endpointAddr}:${toString peer.endpointPort}";
      PersistentKeepalive = 25;
    } else { });
  }) (attrValues peers);
}
