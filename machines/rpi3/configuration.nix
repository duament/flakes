{ config, pkgs, ... }:
let
  wg0 = import ../../lib/wg0.nix;
  smartdnsPort = builtins.toString config.networking.nftables.tproxy.dnsPort;
in {
  sops = {
    defaultSopsFile = ./secrets.yaml;
    age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
    gnupg.sshKeyPaths = [ ];
    secrets.wireguard_key.owner = "systemd-network";
  };

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
      ip saddr ${wg0.subnet} meta l4proto { tcp, udp } th dport ${smartdnsPort} accept;
    '';
    forwardAccept = ''
      iifname wg0 accept;
      oifname wg0 accept;
    '';
    tproxy = {
      enable = true;
      enableLocal = true;
      src = ''
        ip saddr ${wg0.subnet} return;
      '';
      dst = ''
        ip daddr 17.0.0.0/8 accept comment "Apple"
      '';
    };
  };

  systemd.network.netdevs."25-wg0" = {
    enable = true;
    netdevConfig = { Name = "wg0"; Kind = "wireguard"; };
    wireguardConfig = {
      PrivateKeyFile = config.sops.secrets.wireguard_key.path;
      ListenPort = wgPort;
    };
    wireguardPeers = [ { wireguardPeerConfig = {
      AllowedIPs = [ "${wg0.addrPre}2/32" ];
      PersistentKeepalive = 25;
      PublicKey = "BcLh8OUygmCL2m50MREgsAwOLMkF9A+eAhuQDEPaqWI=";
    }; } ];
  };
  systemd.network.networks."25-wg0" = {
    enable = true;
    name = "wg0";
    address = [ (wg0.addrSubnet 1) ];
  };

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    users.rvfg = import ./home.nix;
  };

  environment.systemPackages = with pkgs; [
  ];

  system.stateVersion = "22.11";
}
