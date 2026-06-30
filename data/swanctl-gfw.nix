{ dns }:
# key: suffix
[
  rec {
    host = "de";
    key = "";
    encap = false;
    remote = dns.${host}.ipv6;
    serverIPv4 = "10.5.0.1";
    serverIPv6 = "fdc0::1";
    clientIPv4 = "10.5.0.2";
    clientIPv6 = "fdc0::2";
  }
  rec {
    host = "nl";
    key = "";
    encap = false;
    remote = dns.${host}.ipv6;
    serverIPv4 = "10.5.0.17";
    serverIPv6 = "fdc0::11";
    clientIPv4 = "10.5.0.18";
    clientIPv6 = "fdc0::12";
  }
  rec {
    host = "de2";
    key = "";
    encap = false;
    remote = dns.${host}.ipv4;
    serverIPv4 = "10.5.0.33";
    serverIPv6 = "fdc0::21";
    clientIPv4 = "10.5.0.34";
    clientIPv6 = "fdc0::22";
  }
  rec {
    host = "jp3";
    key = "";
    encap = false;
    remote = dns.${host}.ipv6;
    serverIPv4 = "10.5.0.49";
    serverIPv6 = "fdc0::31";
    clientIPv4 = "10.5.0.50";
    clientIPv6 = "fdc0::32";
  }
]
