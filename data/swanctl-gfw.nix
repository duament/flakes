{ dns }:
# key: suffix
[
  rec {
    id = 1;
    host = "nl";
    key = "";
    encap = true;
    masquerade = true;
    remote = dns.${host}.ipv6;
    serverIPv4 = "10.5.0.17";
    serverIPv6 = "fdc0::11";
    clientIPv4 = "10.5.0.18";
    clientIPv6 = "fdc0::12";
  }
  rec {
    id = 2;
    host = "de2";
    key = "";
    encap = true;
    masquerade = true;
    remote = dns.${host}.ipv4;
    mtu = 1414;
    serverIPv4 = "10.5.0.33";
    serverIPv6 = "fdc0::21";
    clientIPv4 = "10.5.0.34";
    clientIPv6 = "fdc0::22";
  }
  rec {
    id = 3;
    host = "jp3";
    key = "";
    encap = true;
    masquerade = false;
    remote = dns.${host}.ipv6;
    serverIPv4 = "10.5.0.49";
    serverIPv6 = "fdc0::31";
    clientIPv4 = "10.5.0.50";
    clientIPv6 = "fdc0::32";
  }
  rec {
    id = 5;
    host = "g2";
    key = "";
    encap = true;
    masquerade = true;
    remote = dns.${host}.ipv4;
    mtu = 1430;
    serverIPv4 = "10.5.0.5";
    serverIPv6 = "fdc0::5";
    clientIPv4 = "10.5.0.6";
    clientIPv6 = "fdc0::6";
  }
]
