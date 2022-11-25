{ lib, inputs }:
let
  comment_filter = line: builtins.match "^[ \t]*(#.*)?$" line == null;
  china_ipv4_raw = builtins.readFile "${inputs.chn-cidr-list.outPath}/ipv4.txt";
  china_ipv4_list = builtins.filter comment_filter (lib.splitString "\n" china_ipv4_raw);
  china_ipv4 = builtins.concatStringsSep ",\n" china_ipv4_list;
  china_ipv6_raw = builtins.readFile "${inputs.chn-cidr-list.outPath}/ipv6.txt";
  china_ipv6_list = builtins.filter comment_filter (lib.splitString "\n" china_ipv6_raw);
  china_ipv6 = builtins.concatStringsSep ",\n" china_ipv6_list;
in
''
  set special_ipv4 {
    type ipv4_addr
    flags interval
    elements = {
      0.0.0.0/8,
      10.0.0.0/8,
      100.64.0.0/10,
      127.0.0.0/8,
      169.254.0.0/16,
      172.16.0.0/12,
      192.0.0.0/24,
      192.0.2.0/24,
      192.31.196.0/24,
      192.52.193.0/24,
      192.88.99.0/24,
      192.168.0.0/16,
      192.175.48.0/24,
      198.18.0.0/15,
      198.51.100.0/24,
      203.0.113.0/24,
      224.0.0.0/4,
      240.0.0.0-255.255.255.255
    }
  }

  set special_ipv6 {
    type ipv6_addr
    flags interval
    elements = {
      ::,
      ::1,
      ::ffff:0.0.0.0/96,
      64:ff9b:1::/48,
      100::/64,
      2001::/23,
      fc00::/7,
      fe80::/10
    }
  }

  set china_ipv4 {
    type ipv4_addr
    flags interval
    elements = {
      ${china_ipv4}
    }
  }

  set china_ipv6 {
    type ipv6_addr
    flags interval
    elements = {
      ${china_ipv6}
    }
  }
''
