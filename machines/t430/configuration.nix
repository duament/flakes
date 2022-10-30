{ config, lib, ... }:
let
  wg0 = import ../../lib/wg0.nix;
in {
  presets.nogui.enable = true;

  sops.defaultSopsFile = ./secrets.yaml;
  sops.secrets = {
    initrd_ssh_host_ed25519_key = {};
    swanctl = {};
    warp_key.owner = "systemd-network";
    wireguard_key.owner = "systemd-network";
  };

  boot.loader.generationsDir.copyKernels = true;
  boot.loader.systemd-boot.enable = true;
  boot.tmpOnTmpfs = false;

  boot.kernel.sysctl = {
    "net.ipv4.ip_forward" = true;
    "net.ipv6.conf.all.forwarding" = true;
  };

  networking.hostName = "t430";
  networking.nftables.inputAccept = ''
    ip protocol { ah, esp } accept
    udp dport { 500, 4500 } accept
    udp dport ${builtins.toString wg0.port} accept comment "wireguard"
    ip saddr { ${wg0.subnet}, 10.6.9.0/24 } meta l4proto { tcp, udp } th dport 53 accept
  '';
  networking.nftables.forwardAccept = ''
    meta ipsec exists accept
    rt ipsec exists accept
    iifname wg0 accept
    oifname wg0 accept
  '';

  home-manager.users.rvfg = import ./home.nix;

  systemd.network.networks."10-enp1s0" = {
    matchConfig = { PermanentMACAddress = "04:0e:3c:2f:c9:9a"; };
    DHCP = "yes";
    dhcpV6Config = { PrefixDelegationHint = "::/64"; };
  };

  systemd.network.netdevs."25-wg0" = {
    netdevConfig = { Name = "wg0"; Kind = "wireguard"; };
    wireguardConfig = {
      PrivateKeyFile = config.sops.secrets.wireguard_key.path;
      ListenPort = wg0.port;
    };
    wireguardPeers = wg0.peerConfigs;
  };
  systemd.network.networks."25-wg0" = {
    name = "wg0";
    address = [ wg0.gatewaySubnet ];
    networkConfig = { DHCPPrefixDelegation = true; };
    linkConfig = { RequiredForOnline = false; };
  };
  services.wireguardDynamicIPv6.interfaces = [ "wg0" ];

  networking.warp = {
    enable = true;
    endpointAddr = "162.159.193.1";
    mark = 3;
    routingId = "0xac1789";
    keyFile = config.sops.secrets.warp_key.path;
    address = [ "172.16.0.2/32" "2606:4700:110:8721:a63a:693c:cb0d:6de0/128" ];
    table = 20;
    extraMarkRules = "ip saddr 10.6.7.0/24 accept";
  };

  services.smartdns.chinaDns = [ "192.168.2.1" ];
  services.smartdns.settings.bind = [ "[::1]:53" "127.0.0.1:53" "${wg0.gateway}:53" ];
  services.smartdns.settings.address = with builtins;
    attrValues (mapAttrs (name: value: "/${name}.rvf6.com/${value.ip}") wg0.peers) ++ [
      "/t430.rvf6.com/${wg0.gateway}"
      "/owrt.rvf6.com/192.168.2.1"
      "/rpi3.rvf6.com/192.168.2.7"
    ];

  services.uu.enable = true;
  services.uu.wanName = "10-enp1s0";

  services.strongswan-swanctl.enable = true;
  services.strongswan-swanctl.strongswan.extraConfig = ''
    charon {
      plugins {
        attr {
          dns = ${wg0.gateway}
        }
      }
    }
  '';
  environment.etc."swanctl/swanctl.conf".enable = false;
  system.activationScripts.strongswan-swanctl-secret-conf = lib.stringAfter ["etc"] ''
    mkdir -p /etc/swanctl
    ln -sf ${config.sops.secrets.swanctl.path} /etc/swanctl/swanctl.conf
  '';
}
