{
  config,
  pkgs,
  self,
  ...
}:
let
  inherit (self.data) systemdHarden;
  # Phantun Client listens on this UDP address (WireGuard sends packets here)
  phantunLocalUdp = 10112;
  # Phantun Server address (sh.rvf6.com resolves to sh's IPv6)
  phantunRemoteTcp = "sh.rvf6.com:4567";
  # Phantun TUN interface name
  phantunTun = "phantun0";
  # sh's WireGuard public key (fill in after generating on sh:
  #   wg pubkey < sh_wireguard_private.key)
  shPubkey = "FILL_ME_SH_WG_PUBLIC_KEY";
  # WireGuard tunnel subnet
  wgV4Addr = "10.8.1.2/24";
  wgV6Addr = "fd00:1::2/120";
  shV4Addr = "10.8.1.1/32";
  shV6Addr = "fd00:1::1/128";
  # MTU: PPPoE (1492) - IPv6 (40) - TCP (20) - WireGuard (32) = 1400
  # Both ends must use the same MTU
  wgMtu = 1400;
in
{
  # WireGuard private key: reuses the existing router wireguard_key secret
  # (already declared in router/configuration.nix)

  # Masquerade traffic from Phantun TUN to the public interface (ppp0)
  networking.nftables.masquerade = [
    ''iifname "${phantunTun}" oifname "ppp0"''
  ];

  # Allow forwarded traffic between Phantun TUN and WAN interface
  networking.firewall.extraForwardRules = ''
    iifname ${phantunTun} oifname ppp0 accept
  '';

  # Add phantun TUN to WAN-enabled interfaces for firewall forwarding
  router.wanEnabledIfs = [ "phantun0" ];

  # WireGuard interface for sh via Phantun (point-to-point tunnel)
  systemd.network.netdevs."25-wg-phantun" = {
    netdevConfig = {
      Name = "wg-phantun";
      Kind = "wireguard";
      MTUBytes = toString wgMtu;
    };
    wireguardConfig = {
      PrivateKeyFile = config.sops.secrets.wireguard_key.path;
    };
    wireguardPeers = [
      {
        # Allow traffic to sh's tunnel address and any networks behind sh
        AllowedIPs = [
          shV4Addr
          shV6Addr
          "10.0.3.0/23" # sh's ens18 LAN
        ];
        PublicKey = shPubkey;
        # Phantun Client listens locally on UDP, WireGuard sends packets there
        Endpoint = "127.0.0.1:${toString phantunLocalUdp}";
        PersistentKeepalive = 25;
      }
    ];
  };

  systemd.network.networks."25-wg-phantun" = {
    name = "wg-phantun";
    address = [
      wgV4Addr
      wgV6Addr
    ];
  };

  # Phantun Client: listens on local UDP, connects to Phantun Server via TCP
  systemd.services.phantun-client = {
    description = "Phantun Client (UDP to TCP obfuscator for WireGuard)";
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = systemdHarden // {
      ExecStart = "${pkgs.phantun}/bin/phantun_client \
        --local 127.0.0.1:${toString phantunLocalUdp} \
        --remote ${phantunRemoteTcp} \
        --tun ${phantunTun}";
      Restart = "always";
      RestartSec = "5s";
      AmbientCapabilities = [ "CAP_NET_ADMIN" ];
      CapabilityBoundingSet = [ "CAP_NET_ADMIN" ];
      PrivateNetwork = false;
      PrivateDevices = false;
      RestrictAddressFamilies = [
        "AF_UNIX"
        "AF_INET"
        "AF_INET6"
        "AF_NETLINK"
      ];
    };
  };
}
