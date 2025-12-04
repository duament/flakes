{
  config,
  pkgs,
  ...
}:
let

  openvpnPort = 1064;
  openvpnIf = "ov0";

  ifs = [
    "tailscale0"
    "xfrm0"
    openvpnIf
  ];

in
{

  networking.firewall.allowedTCPPorts = [
    openvpnPort
  ];

  router.dnsEnabledIfs = ifs;
  router.lanEnabledIfs = ifs;
  router.wanEnabledIfs = ifs;
  router.wgEnabledIfs = ifs;

  services.tailscale = {
    enable = true;
    package = pkgs.tailscale.override { iptables = pkgs.nftables; };
    openFirewall = true;
    authKeyFile = config.sops.secrets.tailscale_auth_key.path;
    extraUpFlags = [
      "--accept-dns=false"
      "--advertise-exit-node"
      "--netfilter-mode=off"
    ];
  };

  presets.swanctl = {
    enable = true;
    underlyingNetwork = "10-ppp";
    IPv4Prefix = "10.6.9.";
    IPv6Prefix = "fdda::";
    privateKeyFile = config.sops.secrets."pki/router-pkcs8-key".path;
    local.router = {
      auth = "pubkey";
      id = "router.rvf6.com";
      certs = [ config.sops.secrets."pki/router-bundle".path ];
    };
    cacerts = [
      config.sops.secrets."pki/ca".path
      config.sops.secrets."pki/ybk".path
    ];
    devices = [
      "ip16"
      "pixel7"
      "xiaoxin"
    ];
  };

  services.openvpn.servers.server.config = ''
    port ${toString openvpnPort}
    proto tcp
    dev ${openvpnIf}
    dev-type tun
    topology subnet
    ca ${config.sops.secrets."pki/all-ca".path}
    cert ${config.sops.secrets."pki/router-bundle".path}
    key ${config.sops.secrets."pki/router-pkcs8-key".path}
    server 10.6.2.0 255.255.255.0
    server-ipv6 fddb::/64
    push "dhcp-option DNS 10.6.2.1"
    push "dhcp-option DNS fddb::1"
    tls-version-min 1.3
    dh none
  '';

}
