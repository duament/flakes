{ config, pkgs, ... }:
let
  wg0 = import ../../lib/wg0.nix;
in {
  presets.nogui.enable = true;

  sops.defaultSopsFile = ./secrets.yaml;
  sops.secrets = {
    wireguard_key.owner = "systemd-network";
    warp_key.owner = "systemd-network";
    initrd_ssh_host_ed25519_key = {};
  };

  boot.loader.generationsDir.copyKernels = true;
  boot.loader.systemd-boot.enable = true;

  boot.kernel.sysctl = {
    "net.ipv4.ip_forward" = true;
    "net.ipv6.conf.all.forwarding" = true;
  };

  boot.tmpOnTmpfs = false;

  networking.hostName = "rpi3";
  networking.nftables = {
    inputAccept = ''
      udp dport ${builtins.toString wg0.port} accept comment "wireguard"
      ip saddr ${wg0.subnet} meta l4proto { tcp, udp } th dport 53 accept
    '';
    forwardAccept = ''
      iifname wg0 accept
      oifname wg0 accept
    '';
  };

  systemd.network.networks."80-ethernet".dhcpV6Config = { PrefixDelegationHint = "::/64"; };
  systemd.network.netdevs."25-wg0" = {
    enable = true;
    netdevConfig = { Name = "wg0"; Kind = "wireguard"; };
    wireguardConfig = {
      PrivateKeyFile = config.sops.secrets.wireguard_key.path;
      ListenPort = wg0.port;
    };
    wireguardPeers = wg0.peerConfigs;
  };
  systemd.network.networks."25-wg0" = {
    enable = true;
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
  services.smartdns.settings.address = with builtins;
    filter (i: i != "") (attrValues (mapAttrs (name: value: if (value ? endpointAddr) then "" else "/${name}.rvf6.com/${value.ip}") wg0.peers)) ++ [
      "/rpi3.rvf6.com/${wg0.gateway}"
      "/owrt.rvf6.com/192.168.2.1"
      "/t430.rvf6.com/192.168.2.8"
    ];

  home-manager.users.rvfg = import ./home.nix;
}
