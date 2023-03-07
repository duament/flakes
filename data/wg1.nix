with builtins;
rec {
  host = "h.rvf6.com";
  port = 11111;
  addrPre = "10.6.7.";
  mask = 24;
  gateway = "${addrPre}1";
  gatewaySubnet = "${gateway}/${toString mask}";
  subnet = "${addrPre}0/${toString mask}";
  endpoint = "${host}:${toString port}";
  pubkey = "OXMopf5h0m7x2udIdCR7qxBhniN5+coCGqbrm99Lgi4=";
}
