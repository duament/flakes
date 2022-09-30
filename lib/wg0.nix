with builtins;
rec {
  host = "h.rvf6.com";
  port = 11112;
  addrPre = "10.6.6.";
  mask = 24;
  gateway = "${addrPre}1";
  gatewaySubnet = "${gateway}/${toString mask}";
  subnet = "${addrPre}0/${toString mask}";
  endpoint = "${host}:${toString port}";
  pubkey = "LKEU/VwW+TFNuHWwNzOhxh0FVjnfMYHE9bxSx2luNjw=";
  peers = {
    iphone = {
      ip = "${addrPre}2";
      pubkey = "BcLh8OUygmCL2m50MREgsAwOLMkF9A+eAhuQDEPaqWI=";
    };
    work = {
      ip = "${addrPre}10";
      pubkey = "Zwg16+rw0uVJHFWsKj56nc9+eli0/XIYrKxespMbGj0=";
    };
    xiaoxin = {
      ip = "${addrPre}3";
      pubkey = "EB86zlOPDzQLKkByxWznf/deQiIssQ6LAcMuw2oDbRI=";
    };
  };
  peerConfigs = map (peer: {
    wireguardPeerConfig = {
      AllowedIPs = [ "${peer.ip}/32" ];
      PublicKey = peer.pubkey;
    };
  }) (attrValues peers);
}
