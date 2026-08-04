{
  config,
  pkgs,
  self,
  ...
}:
let
  inherit (self.data) systemdHarden;
  # WireGuard listen UDP port (Phantun forwards decapsulated UDP here)
  wgPort = 11112;
  # Phantun Server TCP listen port
  phantunTcpPort = 4567;
  # Phantun TUN interface name
  phantunTun = "phantun0";
  # Phantun Server TUN peer address (default: 192.168.201.2 / fcc9::2)
  phantunV4Peer = "192.168.201.2";
  phantunV6Peer = "fcc9::2";
  # Router's WireGuard public key (fill in after generating on router:
  #   wg pubkey < router_wgphantun_private.key)
  routerPubkey = "FILL_ME_ROUTER_WG_PUBLIC_KEY";
  # WireGuard tunnel subnet
  wgV4Addr = "10.8.1.1/24";
  wgV6Addr = "fd00:1::1/120";
  routerV4Addr = "10.8.1.2/32";
  routerV6Addr = "fd00:1::2/128";
  # MTU: PPPoE (1492) - IPv6 (40) - TCP (20) - WireGuard (32) = 1400
  # Both ends must use the same MTU
  wgMtu = 1400;
in
{
  # Required secrets (add to secrets.yaml manually):
  #   wireguard_key: private key for WireGuard (generate: wg genkey)
  sops.secrets.wireguard_key = {
    owner = "systemd-network";
  };

  # Open TCP port for Phantun Server
  networking.firewall.allowedTCPPorts = [ phantunTcpPort ];

  # Enable IP forwarding (required for WireGuard routing)
  systemd.network.config.networkConfig = {
    IPv4Forwarding = true;
    IPv6Forwarding = true;
  };

  # DNAT: redirect incoming TCP on phantunTcpPort to Phantun's TUN address
  networking.nftables.tables.phantun-dnat = {
    family = "inet";
    content = ''
      chain prerouting {
        type nat hook prerouting priority dstnat; policy accept;
        tcp dport ${toString phantunTcpPort} dnat ip to ${phantunV4Peer}
        tcp dport ${toString phantunTcpPort} dnat ip6 to ${phantunV6Peer}
      }
    '';
  };

  # WireGuard interface (server side: listens for router peer)
  systemd.network.netdevs."25-wg-phantun" = {
    netdevConfig = {
      Name = "wg-phantun";
      Kind = "wireguard";
      MTUBytes = toString wgMtu;
    };
    wireguardConfig = {
      PrivateKeyFile = config.sops.secrets.wireguard_key.path;
      ListenPort = wgPort;
    };
    wireguardPeers = [
      {
        AllowedIPs = [
          routerV4Addr
          routerV6Addr
        ];
        PublicKey = routerPubkey;
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

  # Phantun Server: listens on TCP, forwards decapsulated UDP to WireGuard
  systemd.services.phantun-server = {
    description = "Phantun Server (UDP to TCP obfuscator for WireGuard)";
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = systemdHarden // {
      ExecStart = "${pkgs.phantun}/bin/phantun_server \
        --local ${toString phantunTcpPort} \
        --remote 127.0.0.1:${toString wgPort} \
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
