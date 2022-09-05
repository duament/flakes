rec {
  port = 11112;
  addrPre = "10.6.6.";
  mask = 24;
  addrSubnet = n: "${addrPre}${builtins.toString n}/${builtins.toString mask}";
  subnet = addrSubnet 0;
  endpoint = "h.rvf6.com:${builtins.toString port}";
}
