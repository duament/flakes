{
  ipv4Pre = "10.6.6.";
  ipv6Pre = "fd64::";
  ipv4Mask = 24;
  ipv6Mask = 120;
  control = "t430";
  p2p = [ "or2" "ak" ];
  peers = {
    t430 = {
      id = 1;
      pubkey = "LKEU/VwW+TFNuHWwNzOhxh0FVjnfMYHE9bxSx2luNjw=";
      addr = "h.rvf6.com";
      port = 11112;
    };
    iphone = {
      id = 2;
      pubkey = "BcLh8OUygmCL2m50MREgsAwOLMkF9A+eAhuQDEPaqWI=";
    };
    xiaoxin = {
      id = 3;
      pubkey = "EB86zlOPDzQLKkByxWznf/deQiIssQ6LAcMuw2oDbRI=";
    };
    k2 = {
      id = 4;
      pubkey = "Q+jZnY03JJc20cjwsP60CeClbxhYV9OU0jAEPqKNjTY=";
    };
    k1 = {
      id = 5;
      pubkey = "XQss9kzHipmjizrqUsBYQltHuj3NvyR8+e0hLRfunQE=";
    };
    desktop = {
      id = 6;
      pubkey = "K2YNC2GnrCp0ZEozBkY8KPGwPldJ68/dAsz9bwNOiQg=";
    };
    pixel7 = {
      id = 7;
      pubkey = "3vv0NIrXnQXedkvmTWgHXQMfxC6IcLk4P+cWuGV6qXU=";
    };
    work = {
      id = 10;
      pubkey = "Zwg16+rw0uVJHFWsKj56nc9+eli0/XIYrKxespMbGj0=";
    };
    nl = {
      id = 20;
      pubkey = "Pt/nY6/QPGfVSGRfYCDHRYZ4B+N7BZWKLxEJtEWAYxk=";
      addr = "[2a04:52c0:106:496f::1]"; # nl.rvf6.com
      port = 11111;
    };
    or2 = {
      id = 22;
      pubkey = "y30Ml/mpgpeGz1vPmzn6V6CFshQnvuzub4TLOmhzYXI=";
      addr = "[2603:c020:2:8c00:bdc1:ea21:3fa7:95e6]"; # or2.rvf6.com
      port = 11111;
    };
    or3 = {
      id = 23;
      pubkey = "60W+Pr5CKSpiJ1tY8Dnz+D/vD+r0au3exf3NgZ5DMVM=";
      addr = "[2603:c020:2:8c00:79ea:4095:6b07:144d]"; # or3.rvf6.com
      port = 11111;
    };
    az = {
      id = 24;
      pubkey = "K8CvTzxt9fEatQzYkhdxuxKfNrCQ/XXVhI2vLlRnESE=";
      addr = "104.208.105.145"; # az.rvf6.com
      port = 11111;
    };
    ak = {
      id = 25;
      pubkey = "q4HlrIfkbw9oXa4Bn0mygaOTpsM3SiSIj3gBc+NWWgU=";
      addr = "203.147.229.50"; # ak.rvf6.com
      port = 11111;
    };
  };
}
