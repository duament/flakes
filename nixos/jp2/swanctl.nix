{
  config,
  lib,
  pkgs,
  self,
  ...
}:
let

  inherit (import ../../modules/swanctl-gfw/common.nix { inherit config lib self; })
    # keep-sorted start
    pkcs8
    proposals
    # keep-sorted end
    ;

  interface = "xfrm-jp3-jp2";
  ifId = 4;
  mark = 256;
  table = 256;

  ipv4 = "10.5.0.129";
  ipv6 = "fdc0::81";

in
{
  boot.kernel.sysctl = {
    "net.ipv4.ip_forward" = true;
    "net.ipv6.conf.all.forwarding" = true;
  };

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
  networking.nftables.tables."${interface}-mark" = {
    family = "inet";
    content = ''
      chain ${interface}-mark {
        type filter hook prerouting priority mangle;
        iifname ${interface} ct state new ct mark set ${toString mark}
        ct direction reply ct mark ${toString mark} meta mark set ct mark
      }
      chain ${interface}-mark-output {
        type route hook output priority mangle;
        ct direction reply ct mark ${toString mark} meta mark set ct mark
      }
    '';
  };

  systemd.network = {
    netdevs."25-${interface}" = {
      netdevConfig = {
        Name = interface;
        Kind = "xfrm";
      };
      xfrmConfig = {
        InterfaceId = ifId;
        Independent = true;
      };
    };
    networks."25-${interface}" = {
      name = interface;
      address = [
        "${ipv4}/30"
        "${ipv6}/126"
      ];
      routes = [
        {
          Source = "0.0.0.0/0";
          Table = table;
        }
        {
          Source = "::/0";
          Table = table;
        }
      ];
      routingPolicyRules = [
        {
          FirewallMark = mark;
          Priority = 64;
          Family = "both";
          Table = table;
        }
      ];
    };
  };

  services.strongswan-swanctl = {
    enable = true;
    swanctl.connections.jp3 = {
      inherit proposals;
      remote_addrs = [ self.data.dns.jp3.ipv6 ];
      local.jp2 = {
        auth = "pubkey";
        id = "jp2.rvf6.com";
        certs = [ config.sops.secrets."pki/jp2-bundle".path ];
      };
      remote.jp3 = {
        auth = "pubkey";
        id = "jp3.rvf6.com";
        cacerts = [
          config.sops.secrets."pki/ca".path
          config.sops.secrets."pki/ybk".path
        ];
      };
      children.jp3 = {
        local_ts = [
          "0.0.0.0/0"
          "::/0"
        ];
        remote_ts = [
          "0.0.0.0/0"
          "::/0"
        ];
        esp_proposals = proposals;
        start_action = "trap|start";
      };
      encap = false;
      mobike = false;
      version = 2;
      if_id_in = toString ifId;
      if_id_out = toString ifId;
    };
    strongswan.extraConfig = ''
      charon {
        install_routes = no
      }
    '';
  };

  systemd.services.strongswan-swanctl.serviceConfig.ExecStartPre = [
    "+${pkgs.coreutils}/bin/ln -nsf ${pkcs8 config.networking.hostName} /etc/swanctl/private/private.key"
  ];
}
