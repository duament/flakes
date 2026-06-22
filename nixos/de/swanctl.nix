{
  config,
  pkgs,
  ...
}:
let
  interface = "xfrm-de";
  interfaceId = 2;
  proposals = [
    "aes256gcm16-prfsha384-curve25519-ke1_mlkem768"
  ];
  pkcs8 = config.sops.secrets."pki/de-pkcs8-key".path;
in
{

  networking.firewall = {
    checkReversePath = "loose";
    allowedUDPPorts = [
      500 # IPsec
      4500 # IPsec
    ];
    extraInputRules = ''
      ip protocol { ah, esp } accept
      ip6 nexthdr { ah, esp } accept
    '';
    extraForwardRules = ''
      iifname ${interface} accept
    '';
  };
  networking.nftables.checkRuleset = false;
  networking.nftables.masquerade = [ "iifname ${interface}" ];

  boot.kernel.sysctl = {
    "net.ipv4.ip_forward" = true;
    "net.ipv6.conf.all.forwarding" = true;
  };

  systemd.network.netdevs."25-${interface}" = {
    netdevConfig = {
      Name = interface;
      Kind = "xfrm";
    };
    xfrmConfig = {
      InterfaceId = interfaceId;
      Independent = true;
    };
  };
  systemd.network.networks."25-${interface}" = {
    name = interface;
    address = [
      "10.5.0.1/30"
      "fdc0::1/126"
    ];
    routes = [
      { Destination = "10.8.0.0/16"; }
      { Destination = "10.6.2.0/24"; }
      { Destination = "10.6.9.0/24"; }
      { Destination = "10.6.14.0/24"; }
    ];
  };

  services.strongswan-swanctl = {
    enable = true;
    swanctl = {
      connections.de = {
        inherit proposals;
        local.de = {
          auth = "pubkey";
          id = "de.rvf6.com";
          certs = [ config.sops.secrets."pki/de-bundle".path ];
        };
        remote.router = {
          auth = "pubkey";
          id = "router.rvf6.com";
          cacerts = [
            config.sops.secrets."pki/ca".path
            config.sops.secrets."pki/ybk".path
          ];
        };
        children.de = {
          local_ts = [
            "0.0.0.0/0"
            "::/0"
          ];
          remote_ts = [
            "0.0.0.0/0"
            "::/0"
          ];
          esp_proposals = proposals;
        };
        encap = false;
        mobike = false;
        version = 2;
        if_id_in = toString interfaceId;
        if_id_out = toString interfaceId;
      };
    };
    strongswan.extraConfig = ''
      charon {
        install_routes = no
      }
    '';
  };

  systemd.services.strongswan-swanctl.serviceConfig.ExecStartPre = [
    "+${pkgs.coreutils}/bin/ln -nsf ${pkcs8} /etc/swanctl/private/private.key"
  ];

}
