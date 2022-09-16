{ config, pkgs, ... }:
let
  wg0 = import ../../lib/wg0.nix;
in {
  sops.defaultSopsFile = ./secrets.yaml;
  sops.secrets.wireguard_key.owner = "systemd-network";
  sops.secrets.warp_key.owner = "systemd-network";

  boot.loader = {
    grub.enable = false;
    generic-extlinux-compatible.enable = true;
  };

  boot.kernel.sysctl = {
    "net.ipv4.ip_forward" = true;
  };

  boot.tmpOnTmpfs = false;

  networking.hostName = "rpi3";
  networking.nftables = {
    inputAccept = ''
      udp dport ${builtins.toString wg0.port} accept comment "wireguard";
      ip saddr ${wg0.subnet} meta l4proto { tcp, udp } th dport 53 accept;
    '';
    forwardAccept = ''
      iifname wg0 accept;
      oifname wg0 accept;
    '';
  };

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
  };

  networking.warp = {
    enable = true;
    mark = 3;
    routingId = "routingId";
    pubkey = "bmXOC+F1FxEMF9dyiK2H5/1SUtzH0JuVo51h2wPfgyo=";
    address = [ "172.16.0.2" "2606:4700:110:87da:a33b:6e8e:c964:11af" ];
    table = 20;
  };
  systemd.network.networks."25-warp".routingPolicyRules = [
    { # Bypass OpenWrt container
      routingPolicyRuleConfig = {
        From = "10.6.7.0/24";
        Priority = 9;
      };
    }
  ];

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    users.rvfg = import ./home.nix;
  };

  environment.systemPackages = with pkgs; [
  ];

  system.stateVersion = "22.11";
}
