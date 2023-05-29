{
  peers = {
    t430 = {
      id = 1;
      pubkey = "LKEU/VwW+TFNuHWwNzOhxh0FVjnfMYHE9bxSx2luNjw=";
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
      port = 11111;
    };
    or1 = {
      id = 21;
      pubkey = "WN7044QvfI3G+LXPwLPmnzzWkpxgOBS6QJz41q+taGQ=";
      port = 11111;
    };
    or2 = {
      id = 22;
      pubkey = "y30Ml/mpgpeGz1vPmzn6V6CFshQnvuzub4TLOmhzYXI=";
      port = 11111;
    };
    or3 = {
      id = 23;
      pubkey = "60W+Pr5CKSpiJ1tY8Dnz+D/vD+r0au3exf3NgZ5DMVM=";
      port = 11111;
    };
    az = {
      id = 24;
      pubkey = "K8CvTzxt9fEatQzYkhdxuxKfNrCQ/XXVhI2vLlRnESE=";
      port = 11111;
    };
    ak = {
      id = 25;
      pubkey = "q4HlrIfkbw9oXa4Bn0mygaOTpsM3SiSIj3gBc+NWWgU=";
      port = 40000;
    };
  };
  networks = {
    t430 = {
      ipv4Pre = "10.6.6.";
      ipv4Mask = 24;
      ipv6Pre = "fd64::";
      ipv6Mask = 120;
      # Initiate connection to those peers
      outPeers = [ "nl" "or1" "or2" "or3" "az" "ak" ];
    };
    or2 = {
      ipv4Pre = "10.6.10.";
      ipv4Mask = 24;
      ipv6Pre = "fd66:a::";
      ipv6Mask = 120;
    };
    ak = {
      ipv4Pre = "10.6.11.";
      ipv4Mask = 24;
      ipv6Pre = "fd66:b::";
      ipv6Mask = 120;
    };
  };
}
